// GeneticAlgorithmAgent.swift
// FitEvo
//
// 遺伝的アルゴリズム（GA）を用いたフィットネスエージェント。
//
// アルゴリズム概要:
// GAは生物の進化プロセスを模倣した最適化手法。
// 「個体（Individual）」= 1週間分のトレーニングプラン
// 「個体群（Population）」= 複数の週次プラン候補
// 「適応度（Fitness）」= 報酬関数の評価値
//
// 進化のプロセス（週次更新時に実行）:
// 1. 初期個体群生成（ランダム）
// 2. 適応度評価（報酬関数で評価）
// 3. 選択（トーナメント選択）
// 4. 交叉（一点交叉）
// 5. 突然変異（ランダム種目入れ替え）
// 6. 次世代へ → 2に戻る（50世代繰り返す）
//
// Q-learningとの違い:
// - Q-learning: 行動→状態→報酬のオンライン学習
// - GA: 週次プラン全体を進化させるバッチ最適化

import Foundation

// MARK: - GeneticAlgorithmAgent

/// 遺伝的アルゴリズムで週次プランを最適化するエージェント。
/// 個体群の進化過程をrewardHistoryとして記録し、研究用に可視化可能。
final class GeneticAlgorithmAgent: FitnessAgent {

    // MARK: FitnessAgent Protocol

    let name = "Genetic Algorithm Agent"
    let algorithmDescription = "週次プランを個体として扱い、選択・交叉・突然変異で世代を重ねながら最適解に収束する進化計算手法です。"
    let algorithmType: AlgorithmType = .genetic

    // MARK: GAパラメータ

    /// 個体群サイズ（並行して最適化する週次プランの数）
    private let populationSize: Int = 20

    /// 世代数（週次更新時に実行する進化サイクル数）
    private let generations: Int = 50

    /// 交叉率（親2個体から子を生成する確率）
    private let crossoverRate: Double = 0.8

    /// 突然変異率（各遺伝子がランダムに変化する確率）
    private let mutationRate: Double = 0.1

    /// トーナメントサイズ（選択の競争に参加する個体数）
    private let tournamentSize: Int = 3

    // MARK: 内部状態

    /// 現在の個体群（最適化された週次プラン候補）
    private var population: [Individual] = []

    /// 現在の最良個体（最高適応度の週次プラン）
    private(set) var bestIndividual: Individual?

    private(set) var cumulativeReward: Double = 0.0
    private(set) var episodeCount: Int = 0
    private(set) var rewardHistory: [Double] = []
    var explorationRate: Double = 0.0  // GAは探索率の概念なし（突然変異率を代わりに使用）

    // MARK: 報酬計算

    private let rewardCalculator = RewardCalculator()

    // MARK: - Individual（個体）

    /// GAの個体: 1週間分のトレーニングプラン + 適応度スコア
    struct Individual {
        /// 遺伝子: 7日分のWorkoutActionの配列
        var weeklyPlan: [WorkoutAction]
        /// 適応度スコア（報酬関数で評価）
        var fitness: Double

        init(weeklyPlan: [WorkoutAction]) {
            self.weeklyPlan = weeklyPlan
            self.fitness = 0.0
        }
    }

    // MARK: - Init

    init() {
        // 初期個体群は空（generateWeeklyPlan呼び出し時に初期化）
    }

    // MARK: - FitnessAgent: 行動選択（当日分）

    /// 現在の最良個体から当日の行動を返す。
    /// 最良個体がなければランダムに生成する。
    func selectAction(state: FitEvoState) -> WorkoutAction {
        if let best = bestIndividual {
            // 今日が週の何日目かを計算（簡易: エピソード数から推定）
            let dayIndex = episodeCount % 7
            return best.weeklyPlan[dayIndex]
        }
        // 個体なし → ランダム行動
        return ActionSpace.allActions.randomElement() ?? WorkoutAction.restDayAction
    }

    // MARK: - FitnessAgent: 学習

    /// オンライン学習インターフェース（GAはバッチ処理なので即時更新はしない）
    func learn(state: FitEvoState, action: WorkoutAction, reward: Double, nextState: FitEvoState) {
        episodeCount += 1
        cumulativeReward += reward
        rewardHistory.append(reward)

        // 7エピソード（1週間）ごとに進化を実行
        if episodeCount % 7 == 0 {
            let newPlan = generateWeeklyPlan(state: nextState, availableDays: 5)
            // 最良個体を更新
            bestIndividual = Individual(weeklyPlan: newPlan)
        }
    }

    // MARK: - FitnessAgent: 週次プラン生成（GAのメイン処理）

    /// 遺伝的アルゴリズムを実行して最適な週次プランを生成する。
    ///
    /// 計算量: O(populationSize × generations × 7) ≈ O(7000)
    /// 通常の端末で100ms以内に完了する。
    func generateWeeklyPlan(state: FitEvoState, availableDays: Int) -> [WorkoutAction] {
        // 1. 初期個体群をランダム生成
        population = generateInitialPopulation(state: state, availableDays: availableDays)

        // 2. 世代を繰り返す（メインの進化ループ）
        for generation in 0..<generations {
            // 3. 適応度評価
            evaluateFitness(state: state)

            // 4. 次世代個体群を生成
            var nextGeneration: [Individual] = []

            // エリート主義: 最優秀個体をそのまま次世代に引き継ぐ
            let elites = population.sorted { $0.fitness > $1.fitness }.prefix(2)
            nextGeneration.append(contentsOf: elites)

            // 残りはGA演算子で生成
            while nextGeneration.count < populationSize {
                // 4a. トーナメント選択で親を2個体選ぶ
                let parent1 = tournamentSelection()
                let parent2 = tournamentSelection()

                // 4b. 交叉（crossoverRate の確率で実行）
                var (child1, child2) = crossover(parent1: parent1, parent2: parent2)

                // 4c. 突然変異（各個体独立に適用）
                child1 = mutate(individual: child1, state: state, availableDays: availableDays)
                child2 = mutate(individual: child2, state: state, availableDays: availableDays)

                nextGeneration.append(child1)
                if nextGeneration.count < populationSize {
                    nextGeneration.append(child2)
                }
            }

            population = nextGeneration

            // 最終世代で学習記録を更新
            if generation == generations - 1 {
                evaluateFitness(state: state)
                let best = population.max(by: { $0.fitness < $1.fitness })
                if let best = best {
                    bestIndividual = best
                    rewardHistory.append(best.fitness)
                    cumulativeReward += best.fitness
                }
            }
        }

        return bestIndividual?.weeklyPlan ?? generateRandomPlan(state: state, availableDays: availableDays)
    }

    // MARK: - 判断根拠

    func generateReasoning(for state: FitEvoState) -> String {
        let generation = rewardHistory.count
        let bestFitness = bestIndividual?.fitness ?? 0.0
        return String(format: "GA世代%d回の進化で最適化。適応度: %.3f。%@",
                      generation * generations,
                      bestFitness,
                      defaultBaseReasoning(for: state))
    }

    // MARK: - リセット

    func reset() {
        population = []
        bestIndividual = nil
        cumulativeReward = 0.0
        episodeCount = 0
        rewardHistory = []
    }

    // MARK: - GA演算子実装

    // 1. 初期個体群生成
    private func generateInitialPopulation(state: FitEvoState, availableDays: Int) -> [Individual] {
        (0..<populationSize).map { _ in
            Individual(weeklyPlan: generateRandomPlan(state: state, availableDays: availableDays))
        }
    }

    // 2. 適応度評価
    private func evaluateFitness(state: FitEvoState) {
        for i in 0..<population.count {
            var totalFitness = 0.0
            var currentState = state

            for action in population[i].weeklyPlan {
                let reward = rewardCalculator.calculateReward(
                    state: currentState,
                    action: action,
                    workoutCompleted: !action.restDay
                )
                totalFitness += reward
            }

            population[i].fitness = totalFitness / Double(population[i].weeklyPlan.count)
        }
    }

    // 3. トーナメント選択
    // ランダムに tournamentSize 個体を選び、最も適応度が高い個体を親とする
    private func tournamentSelection() -> Individual {
        var tournament: [Individual] = []
        for _ in 0..<tournamentSize {
            let randomIndex = Int.random(in: 0..<population.count)
            tournament.append(population[randomIndex])
        }
        return tournament.max(by: { $0.fitness < $1.fitness }) ?? population[0]
    }

    // 4. 一点交叉
    // ランダムな交叉点で親2個体の遺伝子を分割・組み合わせる
    private func crossover(parent1: Individual, parent2: Individual) -> (Individual, Individual) {
        guard Double.random(in: 0...1) < crossoverRate else {
            return (parent1, parent2)
        }

        let crossoverPoint = Int.random(in: 1..<7)
        let child1Plan = Array(parent1.weeklyPlan.prefix(crossoverPoint)) +
                         Array(parent2.weeklyPlan.suffix(7 - crossoverPoint))
        let child2Plan = Array(parent2.weeklyPlan.prefix(crossoverPoint)) +
                         Array(parent1.weeklyPlan.suffix(7 - crossoverPoint))

        return (Individual(weeklyPlan: child1Plan), Individual(weeklyPlan: child2Plan))
    }

    // 5. 突然変異
    // 各日のプランを mutationRate の確率でランダムな行動に置き換える
    private func mutate(individual: Individual, state: FitEvoState, availableDays: Int) -> Individual {
        var mutated = individual
        for i in 0..<mutated.weeklyPlan.count {
            if Double.random(in: 0...1) < mutationRate {
                let randomAction = ActionSpace.allActions.randomElement() ?? WorkoutAction.restDayAction
                mutated.weeklyPlan[i] = randomAction
            }
        }
        return mutated
    }

    // MARK: - Helper

    private func generateRandomPlan(state: FitEvoState, availableDays: Int) -> [WorkoutAction] {
        let restDaysNeeded = 7 - min(availableDays, 7)
        var plan: [WorkoutAction] = []

        for dayIndex in 0..<7 {
            // 休息日の均等配置
            let isRestDay = dayIndex < restDaysNeeded
            if isRestDay {
                plan.append(WorkoutAction.restDayAction)
            } else {
                let action = ActionSpace.allActions
                    .filter { !$0.restDay }
                    .randomElement() ?? WorkoutAction.standardWorkout(focusAreas: [.fullBody])
                plan.append(action)
            }
        }

        return plan.shuffled()  // ランダムに日程をシャッフル
    }

    private func defaultBaseReasoning(for state: FitEvoState) -> String {
        if state.overtrainingRisk > 0.6 {
            return "回復を優先した控えめな強度を選択。"
        } else if state.weeklyCompletionRate > 0.7 {
            return "高い継続率に合わせて挑戦的なプランを提案。"
        }
        return "バランスの取れた週次プランに最適化。"
    }
}
