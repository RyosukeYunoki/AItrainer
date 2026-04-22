// RuleBasedAgent.swift
// FitEvo
//
// ルールベースエージェント。
// 専門家の知識をif-elseルールとして実装したベースライン。
// Q-learning・GAと比較することで、強化学習の優位性を示す研究上の対照群。

import Foundation

// MARK: - RuleBasedAgent

/// 専門家ルールによるフィットネスエージェント。
/// データが少ない初期段階での使用と、RLとの比較ベースラインとして機能する。
final class RuleBasedAgent: FitnessAgent {

    // MARK: FitnessAgent Protocol

    let name = "Rule-Based Agent"
    let algorithmDescription = "専門家の知識をルールとして実装したベースライン。強化学習エージェントとの比較対象として使用します。"
    let algorithmType: AlgorithmType = .ruleBased

    private(set) var cumulativeReward: Double = 0.0
    private(set) var episodeCount: Int = 0
    private(set) var rewardHistory: [Double] = []
    var explorationRate: Double = 0.0  // ルールベースは探索なし

    private let rewardCalculator = RewardCalculator()

    // MARK: - FitnessAgent: 行動選択

    /// ルールベースで行動を決定する。
    /// 優先順位:
    /// 1. 重症疲労・睡眠不足 → 完全休息
    /// 2. 高疲労 → 軽めの回復
    /// 3. 連続5日以上 → 休息
    /// 4. 適切なコンディション → 標準ワークアウト
    /// 5. 良好なコンディション → ハードワークアウト
    func selectAction(state: FitEvoState) -> WorkoutAction {
        // ルール1: 極端な疲労・睡眠不足は完全休息
        if state.subjectiveFatigue >= 5 || state.sleepHours < 5.0 {
            return WorkoutAction(
                intensity: .rest,
                duration: 0,
                focusAreas: [],
                exerciseCount: 0,
                restDay: true,
                reasoning: "疲労度が非常に高く（\(state.subjectiveFatigue)/5）、または睡眠が\(String(format: "%.1f", state.sleepHours))時間と不足しています。完全休息を推奨します。"
            )
        }

        // ルール2: 連続5日以上のトレーニング → 強制休息
        if state.consecutiveDays >= 5 {
            return WorkoutAction(
                intensity: .rest,
                duration: 0,
                focusAreas: [],
                exerciseCount: 0,
                restDay: true,
                reasoning: "\(state.consecutiveDays)日連続でトレーニングしています。筋肉の超回復のため休息を取りましょう。"
            )
        }

        // ルール3: 高疲労 → 軽い回復ワークアウト
        if state.subjectiveFatigue >= 4 || state.sleepHours < 6.0 || state.restingHeartRate > 80 {
            return WorkoutAction(
                intensity: .light,
                duration: 30,
                focusAreas: [.core, .legs],
                exerciseCount: 4,
                restDay: false,
                reasoning: buildReasoningText(state: state, intensity: "軽め")
            )
        }

        // ルール4: 適切なコンディション → 標準ワークアウト（部位の局所化）
        if state.subjectiveFatigue <= 3 && state.sleepHours >= 6.0 {
            let focusAreas = rotatingFocusAreas(daysSince: state.daysSinceLastWorkout)
            return WorkoutAction(
                intensity: .moderate,
                duration: 45,
                focusAreas: focusAreas,
                exerciseCount: 5,
                restDay: false,
                reasoning: buildReasoningText(state: state, intensity: "標準")
            )
        }

        // ルール5: 最高コンディション → ハードワークアウト
        if state.subjectiveFatigue <= 2 && state.sleepHours >= 7.0 && state.consecutiveDays <= 2 {
            let focusAreas = rotatingFocusAreas(daysSince: state.daysSinceLastWorkout)
            return WorkoutAction(
                intensity: .hard,
                duration: 60,
                focusAreas: focusAreas,
                exerciseCount: 6,
                restDay: false,
                reasoning: buildReasoningText(state: state, intensity: "ハード")
            )
        }

        // デフォルト: 標準ワークアウト
        return WorkoutAction.standardWorkout(focusAreas: [.fullBody])
    }

    // MARK: - FitnessAgent: 学習（ルールベースは学習なし）

    func learn(state: FitEvoState, action: WorkoutAction, reward: Double, nextState: FitEvoState) {
        // ルールベースは学習しない（ルールは固定）
        episodeCount += 1
        cumulativeReward += reward
        rewardHistory.append(reward)
    }

    // MARK: - FitnessAgent: 週次プラン生成

    func generateWeeklyPlan(state: FitEvoState, availableDays: Int) -> [WorkoutAction] {
        var plan: [WorkoutAction] = []
        var currentState = state

        let workoutDays = Set(selectWorkoutDays(availableDays: availableDays))

        for dayIndex in 0..<7 {
            if workoutDays.contains(dayIndex) {
                var action = selectAction(state: currentState)
                // 週次プランでの疲労蓄積を考慮
                if dayIndex >= 4 && action.intensity == .hard {
                    action = WorkoutAction(
                        intensity: .moderate,
                        duration: 45,
                        focusAreas: action.focusAreas,
                        exerciseCount: 5,
                        restDay: false,
                        reasoning: "週の後半は中程度の強度に調整します。"
                    )
                }
                plan.append(action)
                // 次の日の状態を簡易更新
                currentState.consecutiveDays += 1
                currentState.daysSinceLastWorkout = 0
            } else {
                plan.append(WorkoutAction(
                    intensity: .rest,
                    duration: 0,
                    focusAreas: [],
                    exerciseCount: 0,
                    restDay: true,
                    reasoning: "計画された休息日です。十分な回復を取りましょう。"
                ))
                currentState.consecutiveDays = 0
                currentState.daysSinceLastWorkout += 1
            }
        }

        return plan
    }

    // MARK: - 判断根拠

    func generateReasoning(for state: FitEvoState) -> String {
        return buildReasoningText(state: state, intensity: "最適")
    }

    // MARK: - リセット

    func reset() {
        cumulativeReward = 0.0
        episodeCount = 0
        rewardHistory = []
    }

    // MARK: - Private Helpers

    private func buildReasoningText(state: FitEvoState, intensity: String) -> String {
        var factors: [String] = []

        if state.sleepHours < 6.0 {
            factors.append("睡眠不足（\(String(format: "%.1f", state.sleepHours))h）")
        } else if state.sleepHours >= 7.5 {
            factors.append("十分な睡眠（\(String(format: "%.1f", state.sleepHours))h）")
        }

        if state.subjectiveFatigue >= 4 {
            factors.append("高疲労（\(state.subjectiveFatigue)/5）")
        } else if state.subjectiveFatigue <= 2 {
            factors.append("良好なコンディション（疲労\(state.subjectiveFatigue)/5）")
        }

        if state.consecutiveDays >= 3 {
            factors.append("\(state.consecutiveDays)日連続")
        }

        let baseText = factors.isEmpty
            ? "コンディションは標準的です"
            : factors.joined(separator: "・") + "を考慮"

        return "\(baseText)のため、\(intensity)強度のメニューを推奨します。"
    }

    /// 部位をローテーションして全身をバランスよく鍛える
    private func rotatingFocusAreas(daysSince: Int) -> [MuscleGroup] {
        let schedule: [[MuscleGroup]] = [
            [.chest, .arms],
            [.back, .shoulders],
            [.legs],
            [.core, .fullBody],
            [.chest, .shoulders],
            [.back, .arms],
            [.legs, .core]
        ]
        return schedule[daysSince % schedule.count]
    }

    /// トレーニング日の選択（均等に分散）
    private func selectWorkoutDays(availableDays: Int) -> [Int] {
        let days = min(availableDays, 7)
        switch days {
        case 1: return [1]
        case 2: return [1, 4]
        case 3: return [0, 2, 4]
        case 4: return [0, 2, 4, 6]
        case 5: return [0, 1, 3, 4, 6]
        case 6: return [0, 1, 2, 4, 5, 6]
        case 7: return [0, 1, 2, 3, 4, 5, 6]
        default: return [1, 3, 5]
        }
    }
}
