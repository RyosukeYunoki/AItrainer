// FitEvoState.swift
// FitEvo
//
// 強化学習エージェントの「状態空間」定義。
// HealthKitとアプリ内記録から構成される10次元の状態ベクトル。

import Foundation

// MARK: - FitEvoState

/// 強化学習エージェントが観測する環境の状態。
/// HealthKitデータ（生体情報）とアプリ内記録（行動情報）を組み合わせた複合状態空間。
struct FitEvoState: Equatable, Codable {

    // MARK: HealthKitデータ（生体情報）

    /// 安静時心拍数 [bpm]。高いほど疲労・ストレスのサイン
    var restingHeartRate: Double

    /// 前日の睡眠時間 [h]。回復の質を示す最重要指標
    var sleepHours: Double

    /// 前日の歩数 [steps]。日常活動量の代理指標
    var stepCount: Double

    /// 現在の体重 [kg]
    var weight: Double

    /// 前日のアクティブカロリー消費量 [kcal]
    var activeCalories: Double

    // MARK: アプリ内記録（主観・行動情報）

    /// 主観的疲労度（1=非常に元気 〜 5=非常に疲れている）。ユーザーが毎日入力
    var subjectiveFatigue: Int

    /// 前回トレーニングからの経過日数。過剰休息の検出に使用
    var daysSinceLastWorkout: Int

    /// 直近7日のトレーニング継続率 [0.0〜1.0]。習慣形成の指標
    var weeklyCompletionRate: Double

    /// 連続トレーニング日数。連続記録はモチベーション維持に重要
    var consecutiveDays: Int

    /// 目標達成進捗率 [0.0〜1.0]。ユーザーの長期目標に対する現在地
    var goalProgressRate: Double

    // MARK: - 初期化

    /// デフォルト値（初回起動・HealthKit未許可時のフォールバック）
    static let `default` = FitEvoState(
        restingHeartRate: 65.0,
        sleepHours: 7.0,
        stepCount: 8000,
        weight: 65.0,
        activeCalories: 300,
        subjectiveFatigue: 2,
        daysSinceLastWorkout: 1,
        weeklyCompletionRate: 0.5,
        consecutiveDays: 0,
        goalProgressRate: 0.0
    )

    /// モックデータ（デモ・プレビュー用）
    static let mock = FitEvoState(
        restingHeartRate: 58.0,
        sleepHours: 6.5,
        stepCount: 9200,
        weight: 72.3,
        activeCalories: 420,
        subjectiveFatigue: 2,
        daysSinceLastWorkout: 1,
        weeklyCompletionRate: 0.71,
        consecutiveDays: 5,
        goalProgressRate: 0.34
    )
}

// MARK: - Discretization (Q-learning用の離散化)

extension FitEvoState {

    /// 安静時心拍数を5段階に離散化
    /// - 低: <55 / やや低: 55-65 / 標準: 65-75 / やや高: 75-85 / 高: >85
    var heartRateBucket: Int {
        switch restingHeartRate {
        case ..<55:  return 0
        case 55..<65: return 1
        case 65..<75: return 2
        case 75..<85: return 3
        default:      return 4
        }
    }

    /// 睡眠時間を5段階に離散化
    /// - 不足: <5h / やや不足: 5-6h / 適切: 6-7h / 十分: 7-8h / 過剰: >8h
    var sleepBucket: Int {
        switch sleepHours {
        case ..<5:  return 0
        case 5..<6: return 1
        case 6..<7: return 2
        case 7..<8: return 3
        default:    return 4
        }
    }

    /// 主観的疲労度（すでに1〜5の離散値、0-indexedに変換）
    var fatigueBucket: Int {
        return max(0, min(4, subjectiveFatigue - 1))
    }

    /// 週次継続率を3段階に離散化
    /// - 低: <0.4 / 中: 0.4-0.7 / 高: ≥0.7
    var completionBucket: Int {
        switch weeklyCompletionRate {
        case ..<0.4: return 0
        case 0.4..<0.7: return 1
        default: return 2
        }
    }

    /// 前回トレーニングからの経過日数を3段階に離散化
    var restDaysBucket: Int {
        switch daysSinceLastWorkout {
        case 0: return 0   // 当日トレーニング済み
        case 1: return 1   // 1日休養
        default: return 2  // 2日以上休養
        }
    }

    /// Q-tableのキー生成用：状態を文字列にエンコード
    /// 5^5 = 3125通りの離散状態空間を表現
    var encodedKey: String {
        "\(heartRateBucket)_\(sleepBucket)_\(fatigueBucket)_\(completionBucket)_\(restDaysBucket)"
    }

    // MARK: - 過学習リスク計算

    /// オーバートレーニングリスクスコア [0.0〜1.0]
    /// 報酬関数のペナルティ項に使用する
    var overtrainingRisk: Double {
        var risk = 0.0
        // 睡眠不足リスク
        if sleepHours < 6.0 { risk += 0.3 }
        else if sleepHours < 7.0 { risk += 0.1 }
        // 高疲労リスク
        let fatigueNorm = Double(subjectiveFatigue - 1) / 4.0
        risk += fatigueNorm * 0.4
        // 高安静時心拍リスク（疲労・風邪の兆候）
        if restingHeartRate > 80 { risk += 0.3 }
        else if restingHeartRate > 70 { risk += 0.1 }
        return min(1.0, risk)
    }

    // MARK: - 身体適応スコア

    /// 身体適応スコア [0.0〜1.0]
    /// 適切な運動強度→休養サイクルが取れているかを評価
    var adaptationScore: Double {
        var score = 0.0
        // 適切な睡眠（7-8h が最適）
        if sleepHours >= 7.0 && sleepHours <= 9.0 { score += 0.4 }
        else if sleepHours >= 6.0 { score += 0.2 }
        // 低〜中程度の疲労（疲れすぎず、適度な刺激）
        if subjectiveFatigue <= 2 { score += 0.3 }
        else if subjectiveFatigue == 3 { score += 0.2 }
        // 継続率が高い
        score += weeklyCompletionRate * 0.3
        return min(1.0, score)
    }
}
