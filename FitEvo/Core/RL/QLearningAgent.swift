// QLearningAgent.swift
// FitEvo
//
// Q-learning エージェントの完全実装。
//
// アルゴリズム概要:
// Q-learning は モデルフリーの強化学習アルゴリズムで、環境のダイナミクスを知らずに
// 最適行動価値関数 Q*(s,a) を近似する。
//
// Q値更新式:
//   Q(s,a) ← Q(s,a) + α [ r + γ · max_a' Q(s',a') - Q(s,a) ]
//
//   α: 学習率（新情報への更新量）
//   γ: 割引率（将来報酬の重視度）
//   r: 即時報酬
//   s: 現在状態, a: 行動, s': 次状態
//
// 行動選択: ε-greedy法
//   確率ε でランダム探索（Exploration）
//   確率1-ε で最大Q値の行動を選択（Exploitation）
//
// 状態空間: 5^5 = 3125 状態 (FitEvoStateの離散化)
// 行動空間: ActionSpace.allActions (約20行動)

import Foundation

// MARK: - QLearningAgent

/// ε-greedy Q-learning を実装したフィットネスエージェント。
/// Q値テーブルはメモリ内に保持し、UserDefaultsを介してシリアライズ可能。
final class QLearningAgent: FitnessAgent {

    // MARK: FitnessAgent Protocol

    let name = "Q-Learning Agent"
    let algorithmDescription = "Q値テーブルを用いた強化学習。状態を離散化し、ε-greedy法で探索と活用のトレードオフを管理します。"
    let algorithmType: AlgorithmType = .qLearning

    // MARK: ハイパーパラメータ

    /// 学習率 α ∈ [0,1]。大きいほど新情報を重視（忘れやすい）
    var learningRate: Double

    /// 割引率 γ ∈ [0,1]。大きいほど長期報酬を重視
    var discountFactor: Double

    /// 探索率 ε ∈ [0,1]。大きいほどランダム探索の割合が増える
    var explorationRate: Double

    /// 探索率の最小値（学習が進んでも最低限の探索を維持）
    private let minExplorationRate: Double = 0.05

    /// 探索率の減衰率（エピソードごとに掛け算）
    private let explorationDecay: Double = 0.995

    // MARK: Q値テーブル

    /// Q[state_key][action_key] = Q-value
    /// 状態と行動のペアに対する価値推定を保持する主要データ構造
    private var qTable: [String: [String: Double]] = [:]

    /// Q値の初期値（未訪問の状態-行動ペア）
    private let initialQValue: Double = 0.0

    // MARK: 内部状態（可視化用）

    private(set) var cumulativeReward: Double = 0.0
    private(set) var episodeCount: Int = 0
    private(set) var rewardHistory: [Double] = []

    /// Q値更新の統計情報
    private(set) var totalUpdates: Int = 0
    private(set) var uniqueStatesVisited: Int = 0

    // MARK: 報酬関数

    private var rewardCalculator: RewardCalculator

    // MARK: - Init

    init(
        learningRate: Double = 0.1,
        discountFactor: Double = 0.9,
        explorationRate: Double = 0.3,
        rewardParams: RewardParameters = RewardParameters()
    ) {
        self.learningRate   = learningRate
        self.discountFactor = discountFactor
        self.explorationRate = explorationRate
        self.rewardCalculator = RewardCalculator(params: rewardParams)
        self.loadQTable()
    }

    // MARK: - FitnessAgent: 行動選択

    /// ε-greedy 法で行動を選択する。
    ///
    /// - ε の確率でランダムな行動を選ぶ（探索: 未知の状態-行動を試す）
    /// - 1-ε の確率でQ値が最大の行動を選ぶ（活用: 学習済み知識の利用）
    func selectAction(state: FitEvoState) -> WorkoutAction {
        let stateKey = state.encodedKey
        let actions = ActionSpace.allActions

        // ε-greedy: 探索 vs 活用
        if Double.random(in: 0...1) < explorationRate {
            // ランダム探索
            return actions.randomElement() ?? WorkoutAction.restDayAction
        } else {
            // 貪欲行動: Q値が最高の行動を選択
            return greedyAction(stateKey: stateKey, actions: actions)
        }
    }

    /// Q値が最大の行動を返す（活用フェーズ）
    private func greedyAction(stateKey: String, actions: [WorkoutAction]) -> WorkoutAction {
        let qValues = qTable[stateKey] ?? [:]

        var bestAction = actions[0]
        var bestQValue = qValues[actions[0].encodedKey] ?? initialQValue

        for action in actions {
            let qValue = qValues[action.encodedKey] ?? initialQValue
            if qValue > bestQValue {
                bestQValue = qValue
                bestAction = action
            }
        }

        return bestAction
    }

    // MARK: - FitnessAgent: 学習（Q値更新）

    /// Q値テーブルを1ステップ更新する。
    ///
    /// Bellman方程式に基づく更新:
    /// ```
    /// Q(s,a) ← Q(s,a) + α [ r + γ·max_a' Q(s',a') - Q(s,a) ]
    ///           ←現在値      ←TD誤差 (temporal difference error)
    /// ```
    ///
    /// TD誤差が正 → Q値を増やす（この行動は期待より良かった）
    /// TD誤差が負 → Q値を減らす（この行動は期待より悪かった）
    func learn(state: FitEvoState, action: WorkoutAction, reward: Double, nextState: FitEvoState) {
        let stateKey     = state.encodedKey
        let actionKey    = action.encodedKey
        let nextStateKey = nextState.encodedKey

        // 現在のQ値を取得（未訪問なら初期値）
        let currentQ = qTable[stateKey]?[actionKey] ?? initialQValue

        // 次状態での最大Q値（Bellmanの楽観的評価）
        let nextQValues = qTable[nextStateKey] ?? [:]
        let maxNextQ = ActionSpace.allActions
            .map { nextQValues[$0.encodedKey] ?? initialQValue }
            .max() ?? initialQValue

        // TD誤差: r + γ·max_a' Q(s',a') - Q(s,a)
        let tdError = reward + discountFactor * maxNextQ - currentQ

        // Q値更新
        let newQ = currentQ + learningRate * tdError

        // テーブルに書き込み
        if qTable[stateKey] == nil {
            qTable[stateKey] = [:]
            uniqueStatesVisited += 1
        }
        qTable[stateKey]![actionKey] = newQ

        // 統計更新
        cumulativeReward += reward
        rewardHistory.append(reward)
        totalUpdates += 1

        // Q-tableを永続化
        saveQTable()
    }

    /// エピソード終了時に呼ぶ（探索率の減衰）
    func endEpisode() {
        episodeCount += 1
        // 学習が進むにつれ探索率を減衰（ε-decay）
        explorationRate = max(minExplorationRate, explorationRate * explorationDecay)
    }

    // MARK: - FitnessAgent: 週次プラン生成

    /// 週次トレーニングプランを生成する。
    ///
    /// 現在の状態から7日分の行動を決定する。
    /// 運動可能日にはQ値に基づく最適行動を、休日には休息を配置する。
    func generateWeeklyPlan(state: FitEvoState, availableDays: Int) -> [WorkoutAction] {
        var plan: [WorkoutAction] = []
        let restDaysNeeded = 7 - availableDays

        // 疲労状態を考慮して日程を調整
        var currentState = state
        var consecutiveWorkouts = 0

        for dayIndex in 0..<7 {
            let isRestDay = shouldRest(
                dayIndex: dayIndex,
                availableDays: availableDays,
                consecutiveWorkouts: consecutiveWorkouts,
                state: currentState
            )

            if isRestDay {
                var restAction = WorkoutAction.restDayAction
                restAction.reasoning = generateReasoning(for: currentState)
                plan.append(restAction)
                consecutiveWorkouts = 0
            } else {
                var action = selectAction(state: currentState)
                action.reasoning = generateReasoning(for: currentState)

                // 週の後半は強度を調整（疲労蓄積を考慮）
                if consecutiveWorkouts >= 3 && action.intensity == .hard {
                    action = WorkoutAction(
                        intensity: .moderate,
                        duration: action.duration,
                        focusAreas: action.focusAreas,
                        exerciseCount: action.exerciseCount,
                        restDay: false,
                        reasoning: "連続\(consecutiveWorkouts)日目のため強度を調整しました。"
                    )
                }

                plan.append(action)
                consecutiveWorkouts += 1
            }

            // 次の日の状態を更新（簡易シミュレーション）
            currentState = simulateNextState(state: currentState, action: plan.last!)
        }

        _ = restDaysNeeded  // 未使用変数の警告を抑制
        return plan
    }

    // MARK: - 判断根拠テキスト生成

    /// Q-learning固有の判断根拠：Q値とTD情報を含む
    func generateReasoning(for state: FitEvoState) -> String {
        let baseReasoning = defaultReasoning(for: state)
        let topAction = greedyAction(stateKey: state.encodedKey, actions: ActionSpace.allActions)
        let qValue = qTable[state.encodedKey]?[topAction.encodedKey] ?? 0.0

        if episodeCount == 0 {
            return "データ学習中です。" + baseReasoning
        }

        return String(format: "%@ (Q値: %.3f, エピソード: %d回)", baseReasoning, qValue, episodeCount)
    }

    // MARK: - リセット

    func reset() {
        qTable = [:]
        cumulativeReward = 0.0
        episodeCount = 0
        rewardHistory = []
        totalUpdates = 0
        uniqueStatesVisited = 0
        explorationRate = 0.3
        UserDefaults.standard.removeObject(forKey: "fitevo_qtable")
    }

    // MARK: - 永続化

    private func saveQTable() {
        if let data = try? JSONEncoder().encode(qTable) {
            UserDefaults.standard.set(data, forKey: "fitevo_qtable")
            UserDefaults.standard.set(episodeCount, forKey: "fitevo_episode_count")
            UserDefaults.standard.set(cumulativeReward, forKey: "fitevo_cumulative_reward")
        }
    }

    private func loadQTable() {
        if let data = UserDefaults.standard.data(forKey: "fitevo_qtable"),
           let table = try? JSONDecoder().decode([String: [String: Double]].self, from: data) {
            qTable = table
        }
        episodeCount = UserDefaults.standard.integer(forKey: "fitevo_episode_count")
        cumulativeReward = UserDefaults.standard.double(forKey: "fitevo_cumulative_reward")
    }

    // MARK: - Private Helper Methods

    private func shouldRest(dayIndex: Int, availableDays: Int, consecutiveWorkouts: Int, state: FitEvoState) -> Bool {
        // 連続4日以上は強制休息
        if consecutiveWorkouts >= 4 { return true }
        // 週の運動可能日数で均等に休息日を配置
        let workoutDaysInWeek = min(availableDays, 7)
        let pattern = generateRestPattern(availableDays: workoutDaysInWeek)
        return pattern[dayIndex % 7]
    }

    private func generateRestPattern(availableDays: Int) -> [Bool] {
        // true = 休息日
        switch availableDays {
        case 1: return [false, true, true, true, true, true, true]
        case 2: return [false, true, true, false, true, true, true]
        case 3: return [false, true, false, true, false, true, true]
        case 4: return [false, true, false, false, true, false, false]
        case 5: return [false, false, true, false, false, true, false]
        case 6: return [false, false, false, true, false, false, false]
        case 7: return Array(repeating: false, count: 7)
        default: return [false, true, false, true, false, true, true]
        }
    }

    private func simulateNextState(state: FitEvoState, action: WorkoutAction) -> FitEvoState {
        var next = state
        if !action.restDay {
            next.consecutiveDays = state.consecutiveDays + 1
            next.daysSinceLastWorkout = 0
            // 適切なトレーニングは進捗を少し進める
            next.goalProgressRate = min(1.0, state.goalProgressRate + action.intensity.intensityFactor * 0.02)
        } else {
            next.consecutiveDays = 0
            next.daysSinceLastWorkout = state.daysSinceLastWorkout + 1
        }
        return next
    }

    private func defaultReasoning(for state: FitEvoState) -> String {
        var reasons: [String] = []
        if state.sleepHours < 6.0 {
            reasons.append("睡眠が\(String(format: "%.1f", state.sleepHours))時間と不足")
        }
        if state.subjectiveFatigue >= 4 {
            reasons.append("疲労度\(state.subjectiveFatigue)/5と高め")
        }
        if state.consecutiveDays >= 3 {
            reasons.append("\(state.consecutiveDays)日連続中")
        }
        if state.weeklyCompletionRate >= 0.7 {
            reasons.append("継続率\(Int(state.weeklyCompletionRate * 100))%と優秀")
        }
        return reasons.isEmpty ? "バランスの取れたメニューを提案します。" : reasons.joined(separator: "、") + "のため最適化します。"
    }

    // MARK: - 研究用: Q値統計情報

    /// Q値テーブルの統計情報（研究アピール用）
    var tableStatistics: String {
        let totalEntries = qTable.values.flatMap { $0.values }.count
        let avgQValue = qTable.values.flatMap { $0.values }.reduce(0, +) / Double(max(1, totalEntries))
        return String(format: "訪問状態: %d/%d, Q値エントリ: %d, 平均Q値: %.3f",
                      uniqueStatesVisited, 3125, totalEntries, avgQValue)
    }
}
