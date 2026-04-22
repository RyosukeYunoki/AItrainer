// Exercise.swift
// FitEvo
//
// エクササイズ（種目）のデータモデル定義。
// ExerciseDatabase.jsonから読み込まれ、ワークアウトプランに組み込まれる。

import Foundation

// MARK: - Equipment

/// 使用器具の種別
enum Equipment: String, CaseIterable, Codable {
    case bodyweight      = "bodyweight"       // 自重
    case dumbbell        = "dumbbell"         // ダンベル
    case barbell         = "barbell"          // バーベル
    case machine         = "machine"          // マシン
    case cable           = "cable"            // ケーブル
    case resistanceBand  = "resistance_band"  // チューブ・バンド
    case kettlebell      = "kettlebell"       // ケトルベル

    var displayName: String {
        switch self {
        case .bodyweight:     return "自重"
        case .dumbbell:       return "ダンベル"
        case .barbell:        return "バーベル"
        case .machine:        return "マシン"
        case .cable:          return "ケーブル"
        case .resistanceBand: return "チューブ"
        case .kettlebell:     return "ケトルベル"
        }
    }

    var icon: String {
        switch self {
        case .bodyweight:     return "figure.strengthtraining.functional"
        case .dumbbell:       return "dumbbell.fill"
        case .barbell:        return "dumbbell"
        case .machine:        return "gearshape.fill"
        case .cable:          return "cable.connector"
        case .resistanceBand: return "circle.dotted"
        case .kettlebell:     return "drop.fill"
        }
    }

    /// 器具の簡単な説明文（オンボーディング表示用）
    var description: String {
        switch self {
        case .bodyweight:     return "道具不要。腕立て・スクワットなど自分の体重で行う"
        case .dumbbell:       return "片手で持つ鉄のおもり。自宅でも使いやすい定番器具"
        case .barbell:        return "両手で担ぐ長いバー。高重量トレーニングの王道"
        case .machine:        return "ジムにある専用マシン。安全に部位を集中的に鍛えられる"
        case .cable:          return "ジムの滑車付きマシン。多方向から筋肉に負荷をかけられる"
        case .resistanceBand: return "ゴム製の伸縮バンド。軽量で持ち運び可能、自宅でも使える"
        case .kettlebell:     return "取っ手の付いた鉄の球。全身を動かしながら鍛えられる"
        }
    }
}

// MARK: - Exercise

/// フィットネス種目の定義。
/// ExerciseDatabase.jsonから読み込まれる（100種目以上）。
struct Exercise: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var nameEn: String
    var muscleGroups: [String]
    var equipment: String
    var difficulty: Int           // 難易度 1〜5
    var defaultSets: Int
    var defaultReps: Int
    var defaultDuration: Int?     // 秒単位（有酸素・プランク等）
    var caloriesPerMinute: Double
    var description: String

    // MARK: - 計算プロパティ

    var equipmentEnum: Equipment {
        Equipment(rawValue: equipment) ?? .bodyweight
    }

    var muscleGroupEnums: [MuscleGroup] {
        muscleGroups.compactMap { MuscleGroup(rawValue: $0) }
    }

    var difficultyText: String {
        String(repeating: "★", count: difficulty) + String(repeating: "☆", count: 5 - difficulty)
    }

    var isBodyweight: Bool {
        equipment == Equipment.bodyweight.rawValue
    }
}

// MARK: - WorkoutExercise

/// ワークアウトプランに組み込まれた種目（完了状態・実績を持つ）
struct WorkoutExercise: Identifiable {
    var id: UUID = UUID()
    var exercise: Exercise
    var sets: Int
    var reps: Int
    var restSeconds: Int
    var isCompleted: Bool = false
    var completedSets: Int = 0

    var completionRate: Double {
        guard sets > 0 else { return 0 }
        return Double(completedSets) / Double(sets)
    }

    static func from(_ exercise: Exercise, intensity: WorkoutIntensity) -> WorkoutExercise {
        let repsMultiplier: Double
        let setsCount: Int
        let restSeconds: Int

        switch intensity {
        case .light:
            repsMultiplier = 0.7
            setsCount = 2
            restSeconds = 60
        case .moderate:
            repsMultiplier = 1.0
            setsCount = exercise.defaultSets
            restSeconds = 90
        case .hard:
            repsMultiplier = 1.3
            setsCount = exercise.defaultSets + 1
            restSeconds = 120
        case .rest:
            repsMultiplier = 0
            setsCount = 0
            restSeconds = 0
        }

        return WorkoutExercise(
            exercise: exercise,
            sets: setsCount,
            reps: Int(Double(exercise.defaultReps) * repsMultiplier),
            restSeconds: restSeconds
        )
    }
}

// MARK: - ExerciseDatabaseLoader

/// ExerciseDatabase.jsonを読み込むユーティリティ
enum ExerciseDatabaseLoader {

    private static var _exercises: [Exercise]?

    /// 全エクササイズを取得（キャッシュ済み）
    static func loadAll() -> [Exercise] {
        if let cached = _exercises { return cached }

        guard let url = Bundle.main.url(forResource: "ExerciseDatabase", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let exercises = try? JSONDecoder().decode([Exercise].self, from: data) else {
            return []
        }

        _exercises = exercises
        return exercises
    }

    /// 筋群でフィルタリング
    static func exercises(for muscleGroup: MuscleGroup) -> [Exercise] {
        loadAll().filter { $0.muscleGroups.contains(muscleGroup.rawValue) }
    }

    /// 器具でフィルタリング
    static func exercises(for equipment: Equipment) -> [Exercise] {
        loadAll().filter { $0.equipment == equipment.rawValue }
    }

    /// ワークアウトプランに合わせてエクササイズを選択する
    static func selectExercises(
        for action: WorkoutAction,
        availableEquipment: [Equipment]
    ) -> [WorkoutExercise] {
        let allExercises = loadAll()

        // 部位でフィルタリング
        var candidates = allExercises.filter { exercise in
            action.focusAreas.contains { muscleGroup in
                exercise.muscleGroups.contains(muscleGroup.rawValue)
            }
        }

        // 器具でフィルタリング
        if !availableEquipment.isEmpty {
            candidates = candidates.filter { exercise in
                availableEquipment.contains { $0.rawValue == exercise.equipment }
            }
        }

        // 難易度でフィルタリング（強度に合わせる）
        let targetDifficulty: ClosedRange<Int>
        switch action.intensity {
        case .light:    targetDifficulty = 1...2
        case .moderate: targetDifficulty = 2...3
        case .hard:     targetDifficulty = 3...5
        case .rest:     return []
        }
        candidates = candidates.filter { targetDifficulty.contains($0.difficulty) }

        // 候補が少ない場合はフィルタを緩める
        if candidates.count < action.exerciseCount {
            candidates = allExercises.filter { exercise in
                action.focusAreas.contains { $0.rawValue == exercise.muscleGroups.first }
            }
        }

        // ランダムに必要数選択
        let shuffled = candidates.shuffled()
        let selected = Array(shuffled.prefix(action.exerciseCount))

        return selected.map { WorkoutExercise.from($0, intensity: action.intensity) }
    }
}
