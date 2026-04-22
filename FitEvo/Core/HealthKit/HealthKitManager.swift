// HealthKitManager.swift
// FitEvo
//
// HealthKit連携の中枢。
// 権限リクエスト・データ取得・フォールバック（モックデータ）を管理する。
// 権限がない場合でもアプリが動作するよう、モックデータフォールバックを完全実装している。

import Foundation
import HealthKit
import Observation

// MARK: - HealthKitManager

/// HealthKitへのアクセスを抽象化するマネージャークラス。
/// @Observable を使用してSwiftUI Viewと連携する。
@Observable
final class HealthKitManager {

    // MARK: HealthKit Store

    private let healthStore = HKHealthStore()

    // MARK: Published Properties

    /// HealthKit権限の状態
    private(set) var permissionStatus: HealthKitPermissionStatus = .notDetermined

    /// 今日の健康データ
    private(set) var todayData: DailyHealthData = .mock

    /// 直近7日間の健康データ（グラフ用）
    private(set) var weeklyData: [DailyHealthData] = []

    /// 週次サマリー
    private(set) var weeklySummary: WeeklyHealthSummary = .mock

    /// データ読み込み中フラグ
    private(set) var isLoading: Bool = false

    /// エラーメッセージ
    private(set) var errorMessage: String?

    // MARK: HealthKit読み取り対象のデータ型

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        if let hrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(hrType)
        }
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepType)
        }
        if let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weightType)
        }
        if let caloriesType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(caloriesType)
        }
        return types
    }

    private var writeTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = []
        if let workoutType = HKObjectType.workoutType() as? HKSampleType {
            types.insert(workoutType)
        }
        return types
    }

    // MARK: - 初期化

    init() {
        checkAvailability()
    }

    // MARK: - Public Methods

    /// HealthKitの利用可能性チェック
    func checkAvailability() {
        if HKHealthStore.isHealthDataAvailable() {
            permissionStatus = .notDetermined
        } else {
            permissionStatus = .unavailable
        }
    }

    /// HealthKit権限をリクエストする
    @MainActor
    func requestPermission() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            permissionStatus = .unavailable
            return
        }

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            permissionStatus = .authorized
            await fetchAllData()
        } catch {
            permissionStatus = .denied
            errorMessage = "HealthKitの権限取得に失敗しました: \(error.localizedDescription)"
            // フォールバック: モックデータを使用
            useMockData()
        }
    }

    /// 全健康データを非同期で取得する
    @MainActor
    func fetchAllData() async {
        isLoading = true
        defer { isLoading = false }

        guard permissionStatus == .authorized else {
            useMockData()
            return
        }

        async let heartRate = fetchRestingHeartRate()
        async let sleep     = fetchSleepHours()
        async let steps     = fetchStepCount()
        async let weight    = fetchWeight()
        async let calories  = fetchActiveCalories()

        let (hr, sl, st, wt, ca) = await (heartRate, sleep, steps, weight, calories)

        todayData = DailyHealthData(
            date: Date(),
            restingHeartRate: hr,
            sleepHours: sl,
            stepCount: st,
            weight: wt,
            activeCalories: ca
        )

        await fetchWeeklyData()
    }

    /// モックデータを使用する（HealthKit権限なし時のフォールバック）
    func useMockData() {
        todayData = .mock
        weeklyData = generateMockWeeklyData()
        weeklySummary = .mock
    }

    // MARK: - Private: データ取得メソッド

    /// 安静時心拍数を取得 [bpm]
    private func fetchRestingHeartRate() async -> Double? {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            return nil
        }
        return await fetchLatestQuantity(type: hrType, unit: HKUnit(from: "count/min"))
    }

    /// 昨日の睡眠時間を取得 [時間]
    private func fetchSleepHours() async -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date().addingTimeInterval(-86400))
        let endDate   = calendar.startOfDay(for: Date())

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                // HKCategoryValueSleepAnalysis.asleepUnspecified 等の合計を計算
                let totalSleepSeconds = samples
                    .filter { sample in
                        let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)
                        return value == .asleepUnspecified ||
                               value == .asleepCore ||
                               value == .asleepDeep ||
                               value == .asleepREM
                    }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

                continuation.resume(returning: totalSleepSeconds > 0 ? totalSleepSeconds / 3600 : nil)
            }
            healthStore.execute(query)
        }
    }

    /// 今日の歩数を取得
    private func fetchStepCount() async -> Double? {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return nil
        }
        return await fetchSumQuantity(type: stepType, unit: HKUnit.count(), daysAgo: 0)
    }

    /// 最新の体重を取得 [kg]
    private func fetchWeight() async -> Double? {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return nil
        }
        return await fetchLatestQuantity(type: weightType, unit: HKUnit.gramUnit(with: .kilo))
    }

    /// 昨日のアクティブカロリーを取得 [kcal]
    private func fetchActiveCalories() async -> Double? {
        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return nil
        }
        return await fetchSumQuantity(type: caloriesType, unit: HKUnit.kilocalorie(), daysAgo: 1)
    }

    // MARK: - 週次データ取得

    @MainActor
    private func fetchWeeklyData() async {
        var data: [DailyHealthData] = []

        for daysAgo in (0..<7).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            let dailyData = DailyHealthData(
                date: date,
                restingHeartRate: await fetchRestingHeartRate(),
                sleepHours: await fetchSleepHours(),
                stepCount: await fetchSumQuantity(
                    type: HKQuantityType.quantityType(forIdentifier: .stepCount)!,
                    unit: .count(),
                    daysAgo: daysAgo
                ),
                weight: await fetchWeight(),
                activeCalories: await fetchSumQuantity(
                    type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                    unit: .kilocalorie(),
                    daysAgo: daysAgo
                )
            )
            data.append(dailyData)
        }

        weeklyData = data
        updateWeeklySummary()
    }

    private func updateWeeklySummary() {
        let hrValues = weeklyData.compactMap { $0.restingHeartRate }
        let sleepValues = weeklyData.compactMap { $0.sleepHours }
        let stepValues = weeklyData.compactMap { $0.stepCount }
        let calValues = weeklyData.compactMap { $0.activeCalories }
        let weightValues = weeklyData.compactMap { $0.weight }

        weeklySummary = WeeklyHealthSummary(
            averageRestingHeartRate: hrValues.isEmpty ? 65 : hrValues.reduce(0, +) / Double(hrValues.count),
            averageSleepHours: sleepValues.isEmpty ? 7 : sleepValues.reduce(0, +) / Double(sleepValues.count),
            totalSteps: stepValues.reduce(0, +),
            averageActiveCalories: calValues.isEmpty ? 300 : calValues.reduce(0, +) / Double(calValues.count),
            weightTrend: weightValues.count >= 2 ? (weightValues.last ?? 0) - (weightValues.first ?? 0) : 0
        )
    }

    // MARK: - Generic HealthKit Query Helpers

    /// 最新の数値型サンプルを取得する汎用メソッド
    private func fetchLatestQuantity(type: HKQuantityType, unit: HKUnit) async -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    /// 指定日のデータを合計する汎用メソッド
    private func fetchSumQuantity(type: HKQuantityType, unit: HKUnit, daysAgo: Int) async -> Double? {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date())
        let endDate   = calendar.date(byAdding: .day, value: 1, to: startDate) ?? Date()

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - モックデータ生成

    private func generateMockWeeklyData() -> [DailyHealthData] {
        (0..<7).map { daysAgo in
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            return DailyHealthData(
                date: date,
                restingHeartRate: Double.random(in: 55...75),
                sleepHours: Double.random(in: 5.5...8.5),
                stepCount: Double.random(in: 4000...12000),
                weight: Double.random(in: 70...75),
                activeCalories: Double.random(in: 200...600)
            )
        }.reversed()
    }
}
