// StatCard.swift
// FitEvo
//
// 健康指標・統計データを表示するカードコンポーネント。
// ダッシュボードとプログレス画面で使用する。

import SwiftUI

// MARK: - StatCard

/// 単一の統計値を表示するコンパクトなカード。
struct StatCard: View {
    var icon: String
    var title: String
    var value: String
    var unit: String
    var color: Color
    var trend: Double? = nil    // nil=なし, 正=増加, 負=減少

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                if let trend = trend {
                    TrendIndicator(value: trend)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value)
                        .font(AppTheme.Typography.monospacedLarge)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text(unit)
                        .font(AppTheme.Typography.monospacedSmall)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Text(title)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.md)
        .surfaceCard()
    }
}

// MARK: - TrendIndicator

/// 値の増減を示す小さなインジケーター
struct TrendIndicator: View {
    var value: Double

    var isPositive: Bool { value >= 0 }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2)
            Text(String(format: "%.1f", abs(value)))
                .font(AppTheme.Typography.monospacedSmall)
        }
        .foregroundStyle(isPositive ? AppTheme.Colors.success : AppTheme.Colors.warning)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill((isPositive ? AppTheme.Colors.success : AppTheme.Colors.warning).opacity(0.15))
        )
    }
}

// MARK: - HealthSummaryCard

/// HealthKitデータをサマリー表示するワイドカード。
/// 値がnilの場合「---」と表示し、データが取得できない理由を案内する。
struct HealthSummaryCard: View {
    var heartRate: Double?    // nil = Apple Watchなどのデータなし
    var sleepHours: Double?   // nil = 睡眠記録なし
    var stepCount: Double?    // nil = ヘルスケア未連携
    var isConnected: Bool = false

    private var footerText: String {
        if !isConnected {
            return "ヘルスケアアプリと連携すると実際のデータが表示されます"
        }
        if heartRate == nil {
            return "心拍数の取得にはApple Watchが必要です　 歩数はiPhoneから取得"
        }
        return "iPhoneとApple Watchから取得したデータ"
    }

    private var footerIcon: String {
        if !isConnected { return "exclamationmark.circle" }
        if heartRate == nil { return "applewatch.slash" }
        return "checkmark.circle"
    }

    private var footerColor: Color {
        if !isConnected { return AppTheme.Colors.warning }
        if heartRate == nil { return AppTheme.Colors.textSecondary }
        return AppTheme.Colors.success
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HealthMetricItem(
                    icon: "heart.fill",
                    value: heartRate.map { String(format: "%.0f", $0) } ?? "---",
                    unit: heartRate != nil ? "bpm" : "",
                    label: "安静時心拍",
                    sublabel: heartRate == nil ? "Apple Watch が必要" : nil,
                    color: AppTheme.Colors.danger
                )

                Divider()
                    .background(AppTheme.Colors.separator)
                    .frame(height: 48)

                HealthMetricItem(
                    icon: "moon.zzz.fill",
                    value: sleepHours.map { String(format: "%.1f", $0) } ?? "---",
                    unit: sleepHours != nil ? "h" : "",
                    label: "睡眠",
                    sublabel: sleepHours == nil ? "記録なし" : nil,
                    color: AppTheme.Colors.accent
                )

                Divider()
                    .background(AppTheme.Colors.separator)
                    .frame(height: 48)

                HealthMetricItem(
                    icon: "figure.walk",
                    value: stepCount.map { steps -> String in
                        if steps >= 10000 { return String(format: "%.1f", steps / 10000) }
                        if steps >= 1000  { return String(format: "%.1f", steps / 1000) }
                        return String(Int(steps))
                    } ?? "---",
                    unit: stepCount.map { steps -> String in
                        if steps >= 10000 { return "万歩" }
                        if steps >= 1000  { return "千歩" }
                        return "歩"
                    } ?? "",
                    label: "歩数",
                    sublabel: nil,
                    color: AppTheme.Colors.success
                )
            }
            .padding(.vertical, AppTheme.Spacing.md)
            .padding(.horizontal, AppTheme.Spacing.sm)

            Divider()

            HStack(spacing: 4) {
                Image(systemName: footerIcon)
                    .font(.system(size: 10))
                Text(footerText)
                    .font(AppTheme.Typography.caption)
                Spacer()
            }
            .foregroundStyle(footerColor)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
        }
        .surfaceCard()
    }
}

struct HealthMetricItem: View {
    var icon: String
    var value: String
    var unit: String
    var label: String
    var sublabel: String?   // nil以外: データ未取得の理由を表示
    var color: Color

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .foregroundStyle(value == "---" ? AppTheme.Colors.textTertiary : color)
                .font(.system(size: 14))

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(value == "---" ? AppTheme.Typography.headline : AppTheme.Typography.monospacedLarge)
                    .foregroundStyle(value == "---" ? AppTheme.Colors.textTertiary : AppTheme.Colors.textPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(AppTheme.Typography.monospacedSmall)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }

            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            if let sublabel {
                Text(sublabel)
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background.ignoresSafeArea()
        VStack(spacing: 16) {
            HStack {
                StatCard(icon: "heart.fill", title: "安静時心拍", value: "58", unit: "bpm", color: AppTheme.Colors.danger, trend: -2.0)
                StatCard(icon: "moon.zzz.fill", title: "睡眠", value: "7.2", unit: "h", color: AppTheme.Colors.accent, trend: 0.3)
            }
            HealthSummaryCard(heartRate: 62, sleepHours: 7.5, stepCount: 9200)
        }
        .padding()
    }
}
