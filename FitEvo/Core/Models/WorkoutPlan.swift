// WorkoutPlan.swift
// FitEvo
//
// 週次ワークアウトプランのデータモデル。
// エージェントが生成した7日分のWorkoutActionと、
// 実際の種目リストを管理する。

import Foundation
import SwiftData

// MARK: - WeeklyWorkoutPlan

/// エージェントが生成した1週間分のワークアウトプラン。
/// SwiftDataで永続化される。
@Model
final class WeeklyWorkoutPlan {
    var id: UUID
    var generatedAt: Date
    var algorithmUsed: String   // AlgorithmType.rawValue
    var weekStartDate: Date

    /// 7日分のWorkoutActionをJSON文字列として保存
    var actionsData: Data?

    /// このプランの総合評価スコア（エージェントが計算）
    var planScore: Double

    /// このプランの完了日数
    var completedDays: Int

    var weeklyActions: [WorkoutAction]? {
        guard let data = actionsData else { return nil }
        return try? JSONDecoder().decode([WorkoutAction].self, from: data)
    }

    init(
        actions: [WorkoutAction],
        algorithm: AlgorithmType,
        planScore: Double = 0.0
    ) {
        self.id = UUID()
        self.generatedAt = Date()
        self.algorithmUsed = algorithm.rawValue
        self.weekStartDate = Calendar.current.startOfWeek(for: Date())
        self.actionsData = try? JSONEncoder().encode(actions)
        self.planScore = planScore
        self.completedDays = 0
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}

// MARK: - DayWorkoutPlan

/// 1日分のワークアウトプラン（実際の種目リストを含む）
struct DayWorkoutPlan: Identifiable {
    var id: UUID = UUID()
    var date: Date
    var action: WorkoutAction
    var exercises: [WorkoutExercise]
    var dayLabel: String   // "月", "火" etc.

    var isRestDay: Bool { action.restDay }

    var estimatedDuration: Int { action.duration }

    var totalSets: Int { exercises.reduce(0) { $0 + $1.sets } }

    var completedExercisesCount: Int { exercises.filter { $0.isCompleted }.count }

    var completionRate: Double {
        guard !exercises.isEmpty else { return isRestDay ? 1.0 : 0.0 }
        return Double(completedExercisesCount) / Double(exercises.count)
    }
}
