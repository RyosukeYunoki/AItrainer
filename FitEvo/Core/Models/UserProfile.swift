// UserProfile.swift
// FitEvo
//
// ユーザープロファイルのデータモデル。
// SwiftDataで永続化される。

import Foundation
import SwiftData

// MARK: - FitnessGoal

/// ユーザーのフィットネス目標
enum FitnessGoal: String, CaseIterable, Codable {
    case weightLoss     = "weight_loss"      // 体重減少
    case muscleGain     = "muscle_gain"      // 筋肉増加
    case endurance      = "endurance"        // 持久力向上
    case maintenance    = "maintenance"      // 体型維持

    var displayName: String {
        switch self {
        case .weightLoss:   return "体重減少"
        case .muscleGain:   return "筋肉増加"
        case .endurance:    return "持久力向上"
        case .maintenance:  return "体型維持"
        }
    }

    var icon: String {
        switch self {
        case .weightLoss:   return "arrow.down.circle.fill"
        case .muscleGain:   return "bolt.fill"
        case .endurance:    return "heart.fill"
        case .maintenance:  return "checkmark.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .weightLoss:   return "脂肪燃焼・カロリー消費を最大化するプログラム"
        case .muscleGain:   return "筋肥大・筋力向上に特化した高強度プログラム"
        case .endurance:    return "心肺機能と持久力を高める有酸素中心のプログラム"
        case .maintenance:  return "現在の体型・体力を維持するバランスプログラム"
        }
    }
}

// MARK: - FitnessLevel

/// ユーザーの現在のフィットネスレベル
enum FitnessLevel: String, CaseIterable, Codable {
    case beginner     = "beginner"    // 初心者（運動習慣なし、3ヶ月未満）
    case intermediate = "intermediate" // 中級者（定期的な運動、6ヶ月以上）
    case advanced     = "advanced"    // 上級者（2年以上の継続的なトレーニング）

    var displayName: String {
        switch self {
        case .beginner:     return "初心者"
        case .intermediate: return "中級者"
        case .advanced:     return "上級者"
        }
    }

    var description: String {
        switch self {
        case .beginner:     return "運動習慣が少なく、基礎から始めたい方"
        case .intermediate: return "ある程度の運動習慣があり、さらに向上したい方"
        case .advanced:     return "定期的なトレーニングを継続しており、高強度に挑戦したい方"
        }
    }
}

// MARK: - UserProfile (SwiftData Model)

/// ユーザーのプロファイル情報。SwiftDataで永続化される。
@Model
final class UserProfile {

    // MARK: 基本情報

    var id: UUID
    var createdAt: Date
    var name: String             // ユーザーの呼び名

    // MARK: オンボーディング設定

    var fitnessGoal: String          // FitnessGoal.rawValue
    var fitnessLevel: String         // FitnessLevel.rawValue
    var weeklyWorkoutDays: Int       // 週の運動可能日数 (1〜7)
    var availableEquipment: [String] // Equipment.rawValue の配列

    // MARK: HealthKit関連

    var healthKitAuthorized: Bool

    // MARK: エージェント設定

    var selectedAlgorithm: String    // AlgorithmType.rawValue

    // MARK: 報酬関数パラメータ（JSON文字列として保存）

    var rewardParamsData: Data?

    // MARK: 身体情報

    var currentWeight: Double?       // 現在の体重 [kg]
    var height: Double?              // 身長 [cm]

    // MARK: 目標値

    var targetWeight: Double?        // 目標体重 [kg]
    var targetWeeklyWorkouts: Int    // 週目標トレーニング回数

    // MARK: - 計算プロパティ

    var goal: FitnessGoal {
        FitnessGoal(rawValue: fitnessGoal) ?? .maintenance
    }

    var level: FitnessLevel {
        FitnessLevel(rawValue: fitnessLevel) ?? .beginner
    }

    var equipment: [Equipment] {
        availableEquipment.compactMap { Equipment(rawValue: $0) }
    }

    // MARK: - 初期化

    init(
        name: String = "",
        fitnessGoal: FitnessGoal = .maintenance,
        fitnessLevel: FitnessLevel = .beginner,
        weeklyWorkoutDays: Int = 3,
        availableEquipment: [Equipment] = [.bodyweight]
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.name = name
        self.fitnessGoal = fitnessGoal.rawValue
        self.fitnessLevel = fitnessLevel.rawValue
        self.weeklyWorkoutDays = weeklyWorkoutDays
        self.availableEquipment = availableEquipment.map { $0.rawValue }
        self.healthKitAuthorized = false
        self.selectedAlgorithm = AlgorithmType.ruleBased.rawValue
        self.targetWeeklyWorkouts = weeklyWorkoutDays
    }
}

// MARK: - WorkoutSession (SwiftData Model)

/// 完了したワークアウトセッションの記録。進捗グラフに使用する。
@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    var durationMinutes: Int
    var intensityRaw: String       // WorkoutIntensity.rawValue
    var focusAreasRaw: [String]    // MuscleGroup.rawValue の配列
    var exercisesCompleted: Int
    var totalExercises: Int
    var caloriesBurned: Double
    var reward: Double             // エージェントが付与した報酬
    var algorithmUsed: String      // AlgorithmType.rawValue
    var subjectiveFatigueAfter: Int // ワークアウト後の疲労度 (1〜5)

    var intensity: WorkoutIntensity {
        WorkoutIntensity(rawValue: intensityRaw) ?? .moderate
    }

    var completionRate: Double {
        guard totalExercises > 0 else { return 0 }
        return Double(exercisesCompleted) / Double(totalExercises)
    }

    var isCompleted: Bool {
        completionRate >= 0.8  // 80%以上完了を「完了」とみなす
    }

    init(
        date: Date = Date(),
        durationMinutes: Int,
        intensity: WorkoutIntensity,
        focusAreas: [MuscleGroup],
        exercisesCompleted: Int,
        totalExercises: Int,
        caloriesBurned: Double,
        reward: Double,
        algorithmUsed: AlgorithmType,
        subjectiveFatigueAfter: Int = 3
    ) {
        self.id = UUID()
        self.date = date
        self.durationMinutes = durationMinutes
        self.intensityRaw = intensity.rawValue
        self.focusAreasRaw = focusAreas.map { $0.rawValue }
        self.exercisesCompleted = exercisesCompleted
        self.totalExercises = totalExercises
        self.caloriesBurned = caloriesBurned
        self.reward = reward
        self.algorithmUsed = algorithmUsed.rawValue
        self.subjectiveFatigueAfter = subjectiveFatigueAfter
    }
}

// MARK: - BodyRecord (SwiftData Model)

/// 体型記録。体重・写真・メモを日付付きで保存する。
@Model
final class BodyRecord {
    var id: UUID
    var date: Date
    var weight: Double?      // 体重 [kg]
    var photoData: Data?     // 写真（JPEG圧縮）
    var note: String

    init(date: Date = Date(), weight: Double? = nil, photoData: Data? = nil, note: String = "") {
        self.id = UUID()
        self.date = date
        self.weight = weight
        self.photoData = photoData
        self.note = note
    }
}
