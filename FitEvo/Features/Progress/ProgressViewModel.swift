// ProgressViewModel.swift
// FitEvo

import Foundation
import Observation
import SwiftData

@Observable
final class ProgressViewModel {

    var sessions: [WorkoutSession] = []
    var selectedTimeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week  = "週"
        case month = "月"
        case all   = "全期間"

        var days: Int {
            switch self {
            case .week:  return 7
            case .month: return 30
            case .all:   return 365
            }
        }
    }

    private var agentManager: AgentManager

    init(agentManager: AgentManager) {
        self.agentManager = agentManager
    }

    // MARK: - Computed Stats

    var filteredSessions: [WorkoutSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return sessions.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }

    var totalWorkouts: Int { filteredSessions.count }

    var completionRate: Double {
        guard !filteredSessions.isEmpty else { return 0 }
        return Double(filteredSessions.filter { $0.isCompleted }.count) / Double(filteredSessions.count)
    }

    var averageReward: Double {
        guard !filteredSessions.isEmpty else { return 0 }
        return filteredSessions.map { $0.reward }.reduce(0, +) / Double(filteredSessions.count)
    }

    var averageDurationMinutes: Double {
        guard !filteredSessions.isEmpty else { return 0 }
        return filteredSessions.map { Double($0.durationMinutes) }.reduce(0, +) / Double(filteredSessions.count)
    }

    var totalCalories: Double {
        filteredSessions.map { $0.caloriesBurned }.reduce(0, +)
    }

    // MARK: チャートデータ

    var rewardChartData: [(date: Date, reward: Double)] {
        filteredSessions.map { ($0.date, $0.reward) }
    }

    var cumulativeRewardData: [(date: Date, cumReward: Double)] {
        var cumulative = 0.0
        return filteredSessions.map { session in
            cumulative += session.reward
            return (session.date, cumulative)
        }
    }

    var calorieChartData: [(date: Date, calories: Double)] {
        filteredSessions.map { ($0.date, $0.caloriesBurned) }
    }

    var weeklyVolumeSessions: [(weekLabel: String, count: Int)] {
        // 直近4週の週次ボリュームを集計
        let calendar = Calendar.current
        return (0..<4).reversed().map { weeksAgo in
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: Date()) ?? Date()
            let weekEnd   = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? Date()
            let count = sessions.filter { $0.date >= weekStart && $0.date < weekEnd }.count
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "M/d"
            return (formatter.string(from: weekStart) + "〜", count)
        }
    }

    var currentCumulativeReward: Double {
        agentManager.currentAgent.cumulativeReward
    }

    var currentEpisodeCount: Int {
        agentManager.currentAgent.episodeCount
    }

    var currentExplorationRate: Double {
        agentManager.currentAgent.explorationRate
    }

    var allAgentRewardHistory: [Double] {
        agentManager.currentAgent.rewardHistory
    }

    func loadSessions(from modelContext: ModelContext) {
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        sessions = (try? modelContext.fetch(descriptor)) ?? []
    }
}
