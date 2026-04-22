// AgentProtocol.swift
// FitEvo
//
// 全フィットネスエージェント共通のインターフェース定義。
// Q-learning・遺伝的アルゴリズム・ルールベースが同一プロトコルを実装し、
// UIからは実装の詳細を意識せずにエージェントを使用できる。

import Foundation
import Observation

// MARK: - AlgorithmType

/// 切り替え可能なアルゴリズムの種別
enum AlgorithmType: String, CaseIterable, Codable {
    case qLearning      = "q_learning"
    case genetic        = "genetic"
    case ruleBased      = "rule_based"

    /// 設定画面に表示するユーザー向けの名称
    var displayName: String {
        switch self {
        case .qLearning:  return "学習型AI"
        case .genetic:    return "進化型AI"
        case .ruleBased:  return "シンプルAI"
        }
    }

    /// 設定画面に表示するわかりやすい説明（専門用語なし）
    var algorithmDescription: String {
        switch self {
        case .qLearning:
            return "使うたびに賢くなります。経験を積むほどあなたの身体に合った提案ができるようになります。"
        case .genetic:
            return "週ごとにプランを少しずつ改善します。多様なメニューを試しながら最適なものを見つけます。"
        case .ruleBased:
            return "専門家の知識に基づいた安定したプランを提案します。データが少ない最初の時期に最適です。"
        }
    }

    /// アプリについて画面に表示する技術解説（研究アピール用）
    var technicalDescription: String {
        switch self {
        case .qLearning:
            return """
            Q-learning（Q学習）はモデルフリー強化学習の代表的手法です。状態空間を5段階×5特徴量に離散化（3,125状態）し、Q値テーブルを通じて最適行動価値関数 Q*(s,a) を近似します。

            行動選択にはε-greedy法を採用。確率εでランダム探索（Exploration）、確率1-εで最大Q値の行動を選択（Exploitation）し、探索と活用のトレードオフを管理します。

            Q値更新式（Bellman方程式）:
            Q(s,a) ← Q(s,a) + α[r + γ·max Q(s',a') - Q(s,a)]

            α（学習率）・γ（割引率）・ε（探索率）はSettingsで調整可能です。
            """
        case .genetic:
            return """
            遺伝的アルゴリズム（GA）は生物の進化プロセスを模倣した最適化手法です。「個体」= 週次プラン、「個体群」= 複数の候補プランとして扱います。

            進化のサイクル:
            1. 個体群生成（個体数20）
            2. 適応度評価（報酬関数で評価）
            3. トーナメント選択（サイズ3）
            4. 一点交叉（交叉率0.8）
            5. 突然変異（突然変異率0.1）
            → 50世代繰り返して最適解に収束

            Q学習との違いはオンライン学習ではなくバッチ最適化で、週次プラン全体を同時に最適化する点です。
            """
        case .ruleBased:
            return """
            専門家の知識を条件分岐ルールとして実装したベースラインエージェントです。

            強化学習エージェント（Q学習・GA）との比較対象として機能し、「データが少ない状態でどの程度の推薦精度を出せるか」のベンチマークとなります。

            ルールの優先順位:
            1. 疲労度5 または 睡眠＜5時間 → 完全休息
            2. 連続5日以上 → 強制休息
            3. 疲労度4以上 または 睡眠＜6時間 → 軽め
            4. 標準コンディション → 中程度
            5. 最高コンディション → ハード

            累積報酬グラフでRLエージェントがルールベースを上回る様子を観察できます。
            """
        }
    }

    var icon: String {
        switch self {
        case .qLearning:  return "brain.filled.head.profile"
        case .genetic:    return "arrow.triangle.2.circlepath"
        case .ruleBased:  return "list.bullet.rectangle.fill"
        }
    }
}

// MARK: - FitnessAgent Protocol

/// FitEvoのすべてのAIエージェントが実装すべき共通プロトコル。
/// 研究アピール用に内部状態の可視化メソッドを含む。
protocol FitnessAgent: AnyObject {

    // MARK: メタデータ

    /// エージェント名（表示用）
    var name: String { get }

    /// アルゴリズムの説明文（Settingsに表示）
    var algorithmDescription: String { get }

    /// アルゴリズム種別
    var algorithmType: AlgorithmType { get }

    // MARK: コアインターフェース

    /// 現在の状態から最適な行動を選択する
    /// - Parameter state: 現在の環境状態
    /// - Returns: 推奨ワークアウト行動
    func selectAction(state: FitEvoState) -> WorkoutAction

    /// エージェントを1ステップ更新する（オンライン学習）
    /// - Parameters:
    ///   - state: 行動前の状態
    ///   - action: 選択した行動
    ///   - reward: 得られた報酬
    ///   - nextState: 行動後の状態
    func learn(state: FitEvoState, action: WorkoutAction, reward: Double, nextState: FitEvoState)

    /// 1週間分のトレーニングプランを生成する（週次バッチ更新）
    /// - Parameters:
    ///   - state: 現在の状態
    ///   - availableDays: ユーザーが設定した週あたりの運動可能日数
    /// - Returns: 7日分のWorkoutActionの配列
    func generateWeeklyPlan(state: FitEvoState, availableDays: Int) -> [WorkoutAction]

    // MARK: 研究アピール用：内部状態の可視化

    /// エピソード開始からの累積報酬
    var cumulativeReward: Double { get }

    /// 学習エピソード数（= ワークアウト完了回数）
    var episodeCount: Int { get }

    /// 現在の探索率（ε-greedy の ε、0.0〜1.0）
    var explorationRate: Double { get }

    /// 直近の報酬履歴（グラフ表示用）
    var rewardHistory: [Double] { get }

    /// エージェントのパラメータをリセットする
    func reset()

    /// 現在の状態に対する判断根拠テキストを生成する（ユーザー向け説明）
    /// - Parameter state: 現在の環境状態
    /// - Returns: 日本語の自然文による説明
    func generateReasoning(for state: FitEvoState) -> String
}

// MARK: - Default Implementation

extension FitnessAgent {
    /// デフォルトの判断根拠生成（状態ベースの汎用テキスト）
    func generateReasoning(for state: FitEvoState) -> String {
        var reasons: [String] = []

        if state.sleepHours < 6.0 {
            reasons.append("睡眠時間が\(String(format: "%.1f", state.sleepHours))時間と不足しています")
        } else if state.sleepHours >= 7.5 {
            reasons.append("睡眠が\(String(format: "%.1f", state.sleepHours))時間と十分です")
        }

        if state.subjectiveFatigue >= 4 {
            reasons.append("主観的疲労度が高い（\(state.subjectiveFatigue)/5）")
        } else if state.subjectiveFatigue <= 2 {
            reasons.append("コンディションが良好です（疲労度\(state.subjectiveFatigue)/5）")
        }

        if state.consecutiveDays >= 3 {
            reasons.append("\(state.consecutiveDays)日連続トレーニング中")
        }

        if state.weeklyCompletionRate >= 0.7 {
            reasons.append("今週の継続率\(Int(state.weeklyCompletionRate * 100))%と優秀です")
        }

        if state.overtrainingRisk > 0.6 {
            reasons.append("過学習リスクが高いため回復を優先します")
        }

        if reasons.isEmpty {
            return "状態に基づいてバランスの取れたトレーニングを推奨します。"
        }

        return reasons.joined(separator: "。") + "。"
    }
}

// MARK: - AgentManager

/// エージェントの切り替えと統括管理を行うマネージャー。
/// アプリ全体でシングルトン的に使用される。
@Observable
final class AgentManager {

    // MARK: Properties

    private(set) var currentAgent: any FitnessAgent
    private(set) var algorithmType: AlgorithmType

    /// 報酬関数パラメータ
    var rewardParameters: RewardParameters

    /// 学習パラメータ
    var learningParameters: LearningParameters

    // MARK: 各エージェントのインスタンス（状態を保持するため切り替えても学習が失われない）

    private let qLearningAgent: QLearningAgent
    private let geneticAgent: GeneticAlgorithmAgent
    private let ruleBasedAgent: RuleBasedAgent

    // MARK: Init

    init() {
        let rewardParams = RewardParameters()
        let learnParams = LearningParameters()

        self.rewardParameters = rewardParams
        self.learningParameters = learnParams
        self.algorithmType = .ruleBased  // 初回はルールベースでスタート

        self.qLearningAgent = QLearningAgent(
            learningRate: learnParams.learningRate,
            discountFactor: learnParams.discountFactor,
            explorationRate: learnParams.explorationRate
        )
        self.geneticAgent = GeneticAlgorithmAgent()
        self.ruleBasedAgent = RuleBasedAgent()

        // 初回はルールベースで起動
        self.currentAgent = ruleBasedAgent
    }

    // MARK: Public Methods

    /// アルゴリズムを切り替える（学習済みパラメータは保持される）
    func switchAlgorithm(to type: AlgorithmType) {
        algorithmType = type
        switch type {
        case .qLearning:  currentAgent = qLearningAgent
        case .genetic:    currentAgent = geneticAgent
        case .ruleBased:  currentAgent = ruleBasedAgent
        }
    }

    /// 学習パラメータをQ-learningエージェントに反映する
    func applyLearningParameters() {
        qLearningAgent.learningRate = learningParameters.learningRate
        qLearningAgent.discountFactor = learningParameters.discountFactor
        qLearningAgent.explorationRate = learningParameters.explorationRate
    }

    /// 全エージェントをリセットする
    func resetAll() {
        qLearningAgent.reset()
        geneticAgent.reset()
        ruleBasedAgent.reset()
    }

    /// アプリ起動時にAIが話しかけるメッセージを生成する
    func generateAgentMessage(state: FitEvoState, streakDays: Int, daysSinceLastWorkout: Int, userName: String = "") -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let san = userName.isEmpty ? "" : "\(userName)さん、"

        // 最優先：長期離脱
        if daysSinceLastWorkout >= 7 {
            return "\(san)久しぶりですね！\(daysSinceLastWorkout)日ぶりです。焦らず、今日は軽めからリスタートしましょう。"
        }
        if daysSinceLastWorkout >= 3 {
            return "\(san)\(daysSinceLastWorkout)日ぶりですね。少しずつ取り戻していきましょう！"
        }

        // 高疲労・睡眠不足
        if state.subjectiveFatigue >= 4 && state.sleepHours < 6 {
            return "\(san)疲れが溜まっていますね。今日は無理せず、身体を休ませることも立派なトレーニングです。"
        }
        if state.subjectiveFatigue >= 4 {
            return "\(san)疲労度が高めです。今日は軽いメニューか休息を検討してみてください。"
        }
        if state.sleepHours < 6 {
            return "\(san)睡眠が\(String(format: "%.1f", state.sleepHours))時間と少なめですね。強度を抑えて様子を見ましょう。"
        }

        // 連続記録
        if streakDays >= 7 {
            return "\(san)\(streakDays)日連続達成中！素晴らしいです。オーバートレーニングには気をつけて。"
        }
        if streakDays >= 3 {
            return "\(san)\(streakDays)日連続中！この調子で続けていきましょう！"
        }

        // コンディション良好
        if state.subjectiveFatigue <= 1 && state.sleepHours >= 7.5 {
            return "\(san)コンディション抜群ですね！今日は全力で取り組めそうです。"
        }

        // 時間帯挨拶
        switch hour {
        case 4..<10:
            return "\(san)おはようございます！今日も一緒に頑張りましょう。"
        case 10..<13:
            return "\(san)今日のコンディションはどうですか？最適なメニューを用意しました。"
        case 13..<18:
            return "\(san)こんにちは！今日のトレーニング、一緒に頑張りましょう。"
        case 18..<22:
            return "\(san)お疲れ様です。夕方のトレーニングも効果的ですよ。"
        default:
            return "\(san)夜遅くまでお疲れ様です。無理のない範囲で取り組みましょう。"
        }
    }

    /// エピソード数が一定以上になったらより高度なエージェントに移行する
    func autoEvolveAlgorithm() {
        let episodes = qLearningAgent.episodeCount
        // 7エピソード（約1週間）経過したらQ-learningに移行
        if episodes >= 7 && algorithmType == .ruleBased {
            switchAlgorithm(to: .qLearning)
        }
    }
}

// MARK: - RewardParameters

/// 報酬関数のハイパーパラメータ（Settingsで調整可能）
struct RewardParameters: Codable {
    /// 目標進捗への重み [0.0〜1.0]
    var alpha: Double = 0.4
    /// 継続率ボーナスの重み [0.0〜1.0]
    var beta: Double = 0.3
    /// 過学習ペナルティの重み [0.0〜1.0]
    var gamma: Double = 0.2
    /// 身体適応ボーナスの重み [0.0〜1.0]
    var delta: Double = 0.1
}

// MARK: - LearningParameters

/// Q-learningの学習ハイパーパラメータ（Settingsで調整可能）
struct LearningParameters: Codable {
    /// 学習率 α [0.0〜1.0]：新しい情報をどれだけ重視するか
    var learningRate: Double = 0.1
    /// 割引率 γ [0.0〜1.0]：将来の報酬をどれだけ重視するか
    var discountFactor: Double = 0.9
    /// 探索率 ε [0.0〜1.0]：ランダム探索vs貪欲行動の割合
    var explorationRate: Double = 0.3
}
