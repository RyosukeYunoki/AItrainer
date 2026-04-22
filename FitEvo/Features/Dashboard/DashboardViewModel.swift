// DashboardViewModel.swift
// FitEvo

import Foundation
import Observation
import SwiftData

@Observable
final class DashboardViewModel {

    // MARK: 状態
    var currentState: FitEvoState = .mock
    var todayAction: WorkoutAction = WorkoutAction.standardWorkout(focusAreas: [.chest, .arms])
    var todayReasoning: String = ""
    var subjectiveFatigue: Int = 2
    var weeklyPlan: [WorkoutAction] = []
    var isLoading: Bool = false

    // MARK: AIメッセージ
    var agentMessage: String = ""
    var showAgentMessage: Bool = false

    // MARK: 依存
    private var agentManager: AgentManager
    private var healthKitManager: HealthKitManager

    // MARK: 週次統計
    var weeklyCompletionRate: Double {
        guard !weeklyPlan.isEmpty else { return 0 }
        let completed = weeklyPlan.filter { !$0.restDay }.count
        return Double(completed) / Double(max(1, weeklyPlan.count))
    }

    var streakDays: Int { currentState.consecutiveDays }

    /// HealthKitのデータが実際に取得できているか（falseならサンプル値）
    var isHealthKitConnected: Bool { healthKitManager.permissionStatus == .authorized }

    /// 心拍数（Apple Watchなどのデータがなければnil）
    var rawHeartRate: Double? { isHealthKitConnected ? healthKitManager.todayData.restingHeartRate : nil }
    /// 睡眠時間（ヘルスケアアプリの睡眠記録がなければnil）
    var rawSleepHours: Double? { isHealthKitConnected ? healthKitManager.todayData.sleepHours : nil }
    /// 歩数（iPhone単体でも取得可能）
    var rawStepCount: Double? { isHealthKitConnected ? healthKitManager.todayData.stepCount : nil }

    // MARK: Init

    init(agentManager: AgentManager, healthKitManager: HealthKitManager) {
        self.agentManager = agentManager
        self.healthKitManager = healthKitManager
    }

    // MARK: Public Methods

    @MainActor
    func loadDashboard(profile: UserProfile?) async {
        isLoading = true
        defer { isLoading = false }

        // HealthKit権限確認＆データ取得（認証済みなら即座に復元）
        await healthKitManager.requestPermission()

        // 現在の状態を構築
        let storedFatigue = UserDefaults.standard.integer(forKey: "fitevo_subjective_fatigue")
        let consecutiveDays = UserDefaults.standard.integer(forKey: "fitevo_consecutive_days")
        let weeklyRate = UserDefaults.standard.double(forKey: "fitevo_weekly_completion_rate")
        let daysSinceWorkout = UserDefaults.standard.integer(forKey: "fitevo_days_since_workout")

        currentState = healthKitManager.todayData.toFitEvoState(
            subjectiveFatigue: storedFatigue == 0 ? 2 : storedFatigue,
            daysSinceLastWorkout: daysSinceWorkout,
            weeklyCompletionRate: weeklyRate == 0 ? 0.5 : weeklyRate,
            consecutiveDays: consecutiveDays,
            goalProgressRate: UserDefaults.standard.double(forKey: "fitevo_goal_progress")
        )

        subjectiveFatigue = currentState.subjectiveFatigue

        // エージェントが行動を選択
        todayAction = agentManager.currentAgent.selectAction(state: currentState)
        todayReasoning = agentManager.currentAgent.generateReasoning(for: currentState)

        // 週次プランの生成
        let days = profile?.weeklyWorkoutDays ?? 3
        weeklyPlan = agentManager.currentAgent.generateWeeklyPlan(state: currentState, availableDays: days)

        // エージェントの自動進化チェック
        agentManager.autoEvolveAlgorithm()

        // AIメッセージ生成
        let daysSince = UserDefaults.standard.integer(forKey: "fitevo_days_since_workout")
        agentMessage = agentManager.generateAgentMessage(
            state: currentState,
            streakDays: currentState.consecutiveDays,
            daysSinceLastWorkout: daysSince,
            userName: profile?.name ?? ""
        )
        showAgentMessage = true
    }

    func updateFatigue(_ fatigue: Int) {
        subjectiveFatigue = fatigue
        currentState.subjectiveFatigue = fatigue
        UserDefaults.standard.set(fatigue, forKey: "fitevo_subjective_fatigue")

        // 状態が変わったため行動を再選択
        todayAction = agentManager.currentAgent.selectAction(state: currentState)
        todayReasoning = agentManager.currentAgent.generateReasoning(for: currentState)
    }

    var todayDayOfWeek: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: Date())
    }
}
