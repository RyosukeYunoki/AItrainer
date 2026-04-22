// ProgressRing.swift
// FitEvo
//
// アクティビティリング風のプログレスリングコンポーネント。

import SwiftUI

// MARK: - ProgressRing

/// Apple Watchのアクティビティリングをオマージュした進捗リング。
/// 複数リングを重ねてWeeklyActivityを表現する。
struct ProgressRing: View {
    var progress: Double        // 0.0〜1.0
    var color: Color
    var lineWidth: CGFloat = 16
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            // 背景リング
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // 進捗リング
            Circle()
                .trim(from: 0, to: min(1.0, progress))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(AppTheme.Animation.chart, value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - TripleRing

/// 3つのリングを重ねたウィジェット（週次サマリー表示用）
struct TripleRing: View {
    var workoutProgress: Double    // 今週のワークアウト達成率
    var caloriesProgress: Double   // カロリー目標達成率
    var streakProgress: Double     // 連続記録の達成率

    var body: some View {
        ZStack {
            ProgressRing(progress: workoutProgress, color: AppTheme.Colors.primary, lineWidth: 18, size: 120)
            ProgressRing(progress: caloriesProgress, color: AppTheme.Colors.success, lineWidth: 18, size: 88)
            ProgressRing(progress: streakProgress, color: AppTheme.Colors.accent, lineWidth: 18, size: 56)
        }
    }
}

// MARK: - CircularProgressView

/// テキストラベル付きの円形進捗インジケーター
struct CircularProgressView: View {
    var progress: Double
    var title: String
    var value: String
    var color: Color

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            ZStack {
                ProgressRing(progress: progress, color: color, lineWidth: 8, size: 60)

                Text("\(Int(progress * 100))%")
                    .font(AppTheme.Typography.monospacedSmall)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }

            Text(value)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(color)

            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background.ignoresSafeArea()
        VStack(spacing: 32) {
            TripleRing(workoutProgress: 0.71, caloriesProgress: 0.85, streakProgress: 0.5)

            HStack(spacing: 24) {
                CircularProgressView(progress: 0.71, title: "週次完了", value: "5/7", color: AppTheme.Colors.primary)
                CircularProgressView(progress: 0.85, title: "カロリー", value: "340", color: AppTheme.Colors.success)
                CircularProgressView(progress: 0.5, title: "連続記録", value: "3日", color: AppTheme.Colors.accent)
            }
        }
    }
}
