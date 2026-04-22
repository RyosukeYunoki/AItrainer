// WorkoutAction.swift
// FitEvo
//
// 強化学習エージェントの「行動空間」定義。
// エージェントが選択できるトレーニングの全バリエーションを表現する。

import Foundation

// MARK: - WorkoutIntensity

/// トレーニング強度の4段階分類
enum WorkoutIntensity: String, CaseIterable, Codable {
    case light    = "light"     // 軽め（回復走・ウォーキング・ストレッチ）
    case moderate = "moderate"  // 中程度（標準的なトレーニング）
    case hard     = "hard"      // ハード（高強度・筋肥大向け）
    case rest     = "rest"      // 完全休息

    var displayName: String {
        switch self {
        case .light:    return "ライト"
        case .moderate: return "モデレート"
        case .hard:     return "ハード"
        case .rest:     return "レスト"
        }
    }

    var icon: String {
        switch self {
        case .light:    return "leaf.fill"
        case .moderate: return "flame"
        case .hard:     return "flame.fill"
        case .rest:     return "moon.zzz.fill"
        }
    }

    /// 強度係数（報酬関数・消費カロリー計算に使用）
    var intensityFactor: Double {
        switch self {
        case .rest:     return 0.0
        case .light:    return 0.4
        case .moderate: return 0.7
        case .hard:     return 1.0
        }
    }

    /// Q-learning用インデックス（行動空間の離散表現）
    var index: Int {
        switch self {
        case .light:    return 0
        case .moderate: return 1
        case .hard:     return 2
        case .rest:     return 3
        }
    }
}

// MARK: - MuscleGroup

/// トレーニング対象筋群
enum MuscleGroup: String, CaseIterable, Codable {
    case chest    = "chest"     // 胸
    case back     = "back"      // 背中
    case legs     = "legs"      // 脚（大腿四頭筋・ハムスト・臀部）
    case shoulders = "shoulders" // 肩
    case arms     = "arms"      // 腕（二頭・三頭）
    case core     = "core"      // 体幹
    case fullBody = "full_body" // 全身

    var displayName: String {
        switch self {
        case .chest:     return "胸"
        case .back:      return "背中"
        case .legs:      return "脚"
        case .shoulders: return "肩"
        case .arms:      return "腕"
        case .core:      return "体幹"
        case .fullBody:  return "全身"
        }
    }

    var icon: String {
        switch self {
        case .chest:     return "figure.strengthtraining.traditional"
        case .back:      return "figure.rowing"
        case .legs:      return "figure.run"
        case .shoulders: return "figure.arms.open"
        case .arms:      return "dumbbell.fill"
        case .core:      return "figure.core.training"
        case .fullBody:  return "figure.mixed.cardio"
        }
    }
}

// MARK: - WorkoutAction

/// エージェントが選択する1回分のワークアウト行動。
/// この構造体の配列（7日分）が週次プランを構成する。
struct WorkoutAction: Equatable, Codable, Identifiable {

    var id: UUID = UUID()

    /// トレーニング強度
    var intensity: WorkoutIntensity

    /// トレーニング時間 [分]。選択肢: 15, 30, 45, 60, 90
    var duration: Int

    /// 主要トレーニング部位（複数可）
    var focusAreas: [MuscleGroup]

    /// セッション内の種目数（3〜8）
    var exerciseCount: Int

    /// 休息日推奨フラグ。trueの場合、積極的回復を推奨
    var restDay: Bool

    /// この行動を推奨する根拠テキスト（エージェントが生成）
    var reasoning: String = ""

    // MARK: - 便利なプロパティ

    /// 主要部位の日本語表示
    var focusAreaDisplayName: String {
        focusAreas.map { $0.displayName }.joined(separator: " / ")
    }

    /// 推定消費カロリー（簡易計算）
    var estimatedCalories: Double {
        let baseMET = intensity.intensityFactor * 8.0 + 2.0  // MET値の近似
        let weight = 65.0  // デフォルト体重（実際はUserProfileから取得）
        return baseMET * weight * (Double(duration) / 60.0)
    }

    // MARK: - Q-learning用エンコード

    /// 行動空間の離散インデックス（Q-tableのキーに使用）
    /// intensity(4) × durationBucket(5) = 20種類の基本行動
    var encodedKey: String {
        let durationBucket: Int
        switch duration {
        case ..<20:  durationBucket = 0
        case 20..<35: durationBucket = 1
        case 35..<50: durationBucket = 2
        case 50..<75: durationBucket = 3
        default:     durationBucket = 4
        }
        return "\(intensity.index)_\(durationBucket)"
    }

    // MARK: - 静的ファクトリメソッド

    /// 完全休息日のアクション
    static let restDayAction = WorkoutAction(
        intensity: .rest,
        duration: 0,
        focusAreas: [],
        exerciseCount: 0,
        restDay: true,
        reasoning: "十分な回復時間を確保してください。翌日のパフォーマンス向上に繋がります。"
    )

    /// 軽めの回復ワークアウト
    static func lightRecovery(focusAreas: [MuscleGroup] = [.core]) -> WorkoutAction {
        WorkoutAction(
            intensity: .light,
            duration: 30,
            focusAreas: focusAreas,
            exerciseCount: 4,
            restDay: false,
            reasoning: "疲労回復を促進する軽めのアクティブリカバリーです。"
        )
    }

    /// 標準的なワークアウト
    static func standardWorkout(focusAreas: [MuscleGroup], duration: Int = 45) -> WorkoutAction {
        WorkoutAction(
            intensity: .moderate,
            duration: duration,
            focusAreas: focusAreas,
            exerciseCount: 5,
            restDay: false,
            reasoning: "バランスの良い標準的なトレーニングです。"
        )
    }
}

// MARK: - Action Space Definition

/// Q-learning用の全行動リスト（離散化された行動空間）
enum ActionSpace {
    /// 実用的な行動セットを返す（20行動）
    static let allActions: [WorkoutAction] = {
        var actions: [WorkoutAction] = [WorkoutAction.restDayAction]
        let intensities: [WorkoutIntensity] = [.light, .moderate, .hard]
        let durations = [15, 30, 45, 60, 90]
        let focusCombinations: [[MuscleGroup]] = [
            [.chest, .arms], [.back, .shoulders], [.legs],
            [.core, .fullBody], [.fullBody]
        ]
        for intensity in intensities {
            for duration in durations {
                let focus = focusCombinations[duration / 20 % focusCombinations.count]
                actions.append(WorkoutAction(
                    intensity: intensity,
                    duration: duration,
                    focusAreas: focus,
                    exerciseCount: max(3, min(8, duration / 10)),
                    restDay: false
                ))
            }
        }
        return actions
    }()
}
