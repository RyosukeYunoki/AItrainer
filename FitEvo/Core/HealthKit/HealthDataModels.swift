// HealthDataModels.swift
// FitEvo
//
// HealthKitから取得するデータの型定義。
// アプリ内部での健康データの表現モデル。

import Foundation

// MARK: - DailyHealthData

/// 1日分のHealthKitデータをまとめた構造体。
/// FitEvoStateを構築するために使用される。
struct DailyHealthData {
    /// データの日付
    var date: Date

    /// 安静時心拍数 [bpm]（HealthKitから取得、未取得時はnil）
    var restingHeartRate: Double?

    /// 睡眠時間 [時間]
    var sleepHours: Double?

    /// 歩数
    var stepCount: Double?

    /// 体重 [kg]
    var weight: Double?

    /// アクティブカロリー [kcal]
    var activeCalories: Double?

    // MARK: - FitEvoState変換

    /// HealthKitデータからFitEvoStateを生成する。
    /// HealthKit権限がない場合はデフォルト値でフォールバック。
    func toFitEvoState(
        subjectiveFatigue: Int,
        daysSinceLastWorkout: Int,
        weeklyCompletionRate: Double,
        consecutiveDays: Int,
        goalProgressRate: Double
    ) -> FitEvoState {
        FitEvoState(
            restingHeartRate: restingHeartRate ?? 65.0,
            sleepHours: sleepHours ?? 7.0,
            stepCount: stepCount ?? 8000,
            weight: weight ?? 65.0,
            activeCalories: activeCalories ?? 300,
            subjectiveFatigue: subjectiveFatigue,
            daysSinceLastWorkout: daysSinceLastWorkout,
            weeklyCompletionRate: weeklyCompletionRate,
            consecutiveDays: consecutiveDays,
            goalProgressRate: goalProgressRate
        )
    }

    // MARK: - モックデータ

    static let mock = DailyHealthData(
        date: Date(),
        restingHeartRate: 58.0,
        sleepHours: 6.5,
        stepCount: 9200,
        weight: 72.3,
        activeCalories: 420
    )

    static let mockPoor = DailyHealthData(
        date: Date(),
        restingHeartRate: 82.0,
        sleepHours: 4.5,
        stepCount: 3200,
        weight: 72.5,
        activeCalories: 120
    )
}

// MARK: - WeeklyHealthSummary

/// 直近7日間の健康データの集計。
/// 進捗分析画面やエージェントの週次評価に使用する。
struct WeeklyHealthSummary {
    var averageRestingHeartRate: Double
    var averageSleepHours: Double
    var totalSteps: Double
    var averageActiveCalories: Double
    var weightTrend: Double   // 体重変化量 [kg/week]（負が減少）

    /// モックデータ
    static let mock = WeeklyHealthSummary(
        averageRestingHeartRate: 62.0,
        averageSleepHours: 7.2,
        totalSteps: 65000,
        averageActiveCalories: 380,
        weightTrend: -0.2
    )
}

// MARK: - HealthKitPermissionStatus

/// HealthKit権限の状態
enum HealthKitPermissionStatus {
    case notDetermined   // 未決定（初回起動時）
    case authorized      // 許可済み
    case denied          // 拒否済み
    case unavailable     // HealthKit非対応デバイス（iPadなど）
}
