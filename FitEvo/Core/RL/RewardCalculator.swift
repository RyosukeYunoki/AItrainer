// RewardCalculator.swift
// FitEvo
//
// 強化学習の報酬関数実装。
// 多目的最適化の設計で、ユーザーの目標・継続性・過学習防止・身体適応を同時に考慮する。
// これはアプリの研究的な核心部分。

import Foundation

// MARK: - RewardCalculator

/// FitEvoの報酬関数。
/// 4つの報酬項（目標進捗・継続・過学習ペナルティ・身体適応）の加重和で設計される。
///
/// 報酬設計の哲学:
/// - 短期的な強度ではなく長期的な継続性と安全性を最大化する
/// - ユーザーの主観的コンディションを明示的に組み込む
/// - 過学習リスクをペナルティとして組み込むことで怪我を予防する
struct RewardCalculator {

    // MARK: - 報酬パラメータ

    /// 目標進捗への貢献の重み（デフォルト: 0.4）
    var alpha: Double
    /// 継続率ボーナスの重み（デフォルト: 0.3）
    var beta: Double
    /// 過学習ペナルティの重み（デフォルト: 0.2）
    var gamma: Double
    /// 身体適応ボーナスの重み（デフォルト: 0.1）
    var delta: Double

    init(params: RewardParameters = RewardParameters()) {
        self.alpha = params.alpha
        self.beta  = params.beta
        self.gamma = params.gamma
        self.delta = params.delta
    }

    // MARK: - メイン報酬計算

    /// 状態と行動のペアから報酬を計算する。
    ///
    /// ```
    /// R = α·progressReward + β·consistencyBonus - γ·recoveryPenalty + δ·adaptationBonus
    /// ```
    ///
    /// - Parameters:
    ///   - state: 行動前の環境状態
    ///   - action: エージェントが選択した行動
    ///   - nextState: 行動実行後の環境状態（利用可能な場合）
    ///   - workoutCompleted: ユーザーがワークアウトを完了したか
    /// - Returns: スカラー報酬値（通常 -1.0 〜 +1.0 の範囲）
    func calculateReward(
        state: FitEvoState,
        action: WorkoutAction,
        nextState: FitEvoState? = nil,
        workoutCompleted: Bool = true
    ) -> Double {

        // 項1: 目標進捗への貢献
        // ワークアウト完了時に進捗する。強度が高いほど進捗量が大きい
        let progressReward = alpha * goalProgressScore(
            state: state,
            action: action,
            completed: workoutCompleted
        )

        // 項2: 継続率ボーナス
        // 継続率が高いほどボーナスが大きい（習慣形成を報酬で促進）
        let consistencyBonus = beta * state.weeklyCompletionRate * (workoutCompleted ? 1.2 : 0.8)

        // 項3: 過学習ペナルティ
        // 疲労・睡眠不足の状態でハードなワークアウトを選択するとペナルティ
        let recoveryPenalty = gamma * overtrainingPenalty(state: state, action: action)

        // 項4: 身体適応ボーナス
        // 適切な刺激→回復サイクルが取れているときに加算
        let adaptationBonus = delta * state.adaptationScore

        // 最終報酬（クリッピングして -1.0〜+1.5 に収める）
        let rawReward = progressReward + consistencyBonus - recoveryPenalty + adaptationBonus
        return max(-1.0, min(1.5, rawReward))
    }

    // MARK: - 報酬サブコンポーネント

    /// 目標進捗スコア [0.0〜1.0]
    ///
    /// ユーザーの目標種別と行動の適合性を評価する。
    /// ワークアウト未完了の場合はペナルティを返す。
    private func goalProgressScore(
        state: FitEvoState,
        action: WorkoutAction,
        completed: Bool
    ) -> Double {
        guard completed else { return -0.2 }  // 未完了ペナルティ
        guard !action.restDay else { return 0.1 }  // 休息日は小さな正報酬

        // 強度と継続性に基づく基本スコア
        let intensityScore = action.intensity.intensityFactor
        let durationScore = min(1.0, Double(action.duration) / 60.0)
        let progressContribution = (intensityScore * 0.6 + durationScore * 0.4)

        // 目標進捗率が低い間は積極的なトレーニングを奨励
        let urgencyMultiplier = state.goalProgressRate < 0.5 ? 1.2 : 1.0

        return min(1.0, progressContribution * urgencyMultiplier)
    }

    /// 過学習ペナルティ [0.0〜1.0]
    ///
    /// 疲労・睡眠不足・高安静時心拍の状態でのハードトレーニングを罰する。
    /// これが「怪我を予防するAIコーチ」の研究的に重要な部分。
    func overtrainingPenalty(state: FitEvoState, action: WorkoutAction) -> Double {
        guard !action.restDay else { return 0.0 }

        var penalty = 0.0

        // 睡眠不足 × 高強度 の組み合わせに大きなペナルティ
        if state.sleepHours < 6.0 && action.intensity == .hard {
            penalty += 0.5
        } else if state.sleepHours < 6.0 && action.intensity == .moderate {
            penalty += 0.2
        }

        // 高疲労状態でのハードトレーニング
        if state.subjectiveFatigue >= 4 {
            penalty += action.intensity.intensityFactor * 0.4
        }

        // 高安静時心拍（体調不良の可能性）でのトレーニング
        if state.restingHeartRate > 80 && action.intensity != .light {
            penalty += 0.3
        }

        // 休息なしで連続5日以上
        if state.consecutiveDays >= 5 && action.intensity == .hard {
            penalty += 0.2
        }

        return min(1.0, penalty)
    }

    // MARK: - 即時報酬計算（ワークアウト中）

    /// セット完了時の即時報酬（励ましフィードバック用）
    func immediateReward(completedSets: Int, totalSets: Int) -> Double {
        let completionRate = Double(completedSets) / Double(max(1, totalSets))
        return completionRate * 0.5  // 完了率に比例した小さな正報酬
    }
}

// MARK: - RewardBreakdown

/// 報酬の内訳（研究アピール用の可視化データ）
struct RewardBreakdown {
    let progressComponent: Double
    let consistencyComponent: Double
    let penaltyComponent: Double
    let adaptationComponent: Double
    let total: Double

    var description: String {
        String(format: """
        報酬内訳:
        • 目標進捗 (α=0.4): %+.3f
        • 継続ボーナス (β=0.3): %+.3f
        • 過学習ペナルティ (γ=0.2): -%+.3f
        • 適応ボーナス (δ=0.1): %+.3f
        ─────────────────
        合計報酬: %+.3f
        """, progressComponent, consistencyComponent, penaltyComponent, adaptationComponent, total)
    }
}

extension RewardCalculator {
    /// 詳細な報酬内訳を返す（Settings・研究用）
    func calculateDetailedReward(
        state: FitEvoState,
        action: WorkoutAction,
        workoutCompleted: Bool = true
    ) -> RewardBreakdown {
        let progress   = alpha * goalProgressScore(state: state, action: action, completed: workoutCompleted)
        let consistency = beta * state.weeklyCompletionRate * (workoutCompleted ? 1.2 : 0.8)
        let penalty    = gamma * overtrainingPenalty(state: state, action: action)
        let adaptation = delta * state.adaptationScore
        let total      = max(-1.0, min(1.5, progress + consistency - penalty + adaptation))

        return RewardBreakdown(
            progressComponent: progress,
            consistencyComponent: consistency,
            penaltyComponent: penalty,
            adaptationComponent: adaptation,
            total: total
        )
    }
}
