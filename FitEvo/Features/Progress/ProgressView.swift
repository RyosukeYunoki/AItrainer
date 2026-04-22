// ProgressView.swift
// FitEvo
//
// 進捗分析画面。
// Swift Chartsを使ったグラフと、強化学習エージェントの累積報酬グラフを表示する。
// 研究アピール用の最重要画面。

import SwiftUI
import SwiftData
import Charts

// MARK: - ProgressAnalyticsView

struct ProgressAnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: ProgressViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {

                        // 期間セレクター
                        TimeRangeSelector(selected: $viewModel.selectedTimeRange)

                        // サマリーカード
                        ProgressSummaryCards(viewModel: viewModel)

                        // 消費カロリー推移グラフ
                        WorkoutCalorieChart(data: viewModel.calorieChartData)

                        // 週次ボリューム棒グラフ
                        WeeklyVolumeChart(data: viewModel.weeklyVolumeSessions)

                        // 継続カレンダー
                        ActivityCalendarView(sessions: viewModel.sessions)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("進捗分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
            .onAppear {
                viewModel.loadSessions(from: modelContext)
            }
        }
    }
}

// MARK: - Time Range Selector

struct TimeRangeSelector: View {
    @Binding var selected: ProgressViewModel.TimeRange

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProgressViewModel.TimeRange.allCases, id: \.rawValue) { range in
                Button(action: { withAnimation { selected = range } }) {
                    Text(range.rawValue)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(selected == range ? .white : AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                                .fill(selected == range ? AppTheme.Colors.primary : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(AppTheme.Colors.surface)
        )
    }
}

// MARK: - Summary Cards

struct ProgressSummaryCards: View {
    var viewModel: ProgressViewModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.sm) {
            StatCard(
                icon: "bolt.fill",
                title: "ワークアウト回数",
                value: "\(viewModel.totalWorkouts)",
                unit: "回",
                color: AppTheme.Colors.primary
            )
            StatCard(
                icon: "checkmark.circle.fill",
                title: "完了率",
                value: "\(Int(viewModel.completionRate * 100))",
                unit: "%",
                color: AppTheme.Colors.success
            )
            StatCard(
                icon: "flame.fill",
                title: "消費カロリー",
                value: String(format: "%.0f", viewModel.totalCalories),
                unit: "kcal",
                color: AppTheme.Colors.warning
            )
            StatCard(
                icon: "clock.fill",
                title: "平均時間",
                value: String(format: "%.0f", viewModel.averageDurationMinutes),
                unit: "分",
                color: AppTheme.Colors.accent
            )
        }
    }
}

// MARK: - Workout Calorie Chart

struct WorkoutCalorieChart: View {
    var data: [(date: Date, calories: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(AppTheme.Colors.warning)
                Text("消費カロリーの推移")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
            }

            if data.isEmpty {
                EmptyChartPlaceholder(message: "ワークアウトを完了するとグラフが表示されます")
            } else {
                Chart {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, point in
                        BarMark(
                            x: .value("日付", point.date, unit: .day),
                            y: .value("カロリー", point.calories)
                        )
                        .foregroundStyle(AppTheme.Colors.gradientPrimary)
                        .cornerRadius(4)

                        if data.count > 1 {
                            LineMark(
                                x: .value("日付", point.date, unit: .day),
                                y: .value("カロリー", point.calories)
                            )
                            .foregroundStyle(AppTheme.Colors.primary.opacity(0.5))
                            .interpolationMethod(.linear)
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine(stroke: StrokeStyle(dash: [4]))
                            .foregroundStyle(AppTheme.Colors.separator)
                        AxisValueLabel(format: .dateTime.month().day())
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(dash: [4]))
                            .foregroundStyle(AppTheme.Colors.separator)
                        AxisValueLabel {
                            if let cal = value.as(Double.self) {
                                Text("\(Int(cal))kcal")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .chartLegend(.hidden)
            }

            Text("1回のトレーニングで消費したカロリーを記録します")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.md)
        .surfaceCard()
    }
}

// MARK: - Weekly Volume Chart

struct WeeklyVolumeChart: View {
    var data: [(weekLabel: String, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(AppTheme.Colors.primary)
                Text("週次トレーニング回数")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }

            if data.allSatisfy({ $0.count == 0 }) {
                EmptyChartPlaceholder(message: "データが蓄積されるとグラフが表示されます")
            } else {
                Chart {
                    ForEach(data, id: \.weekLabel) { point in
                        BarMark(
                            x: .value("週", point.weekLabel),
                            y: .value("回数", point.count)
                        )
                        .foregroundStyle(AppTheme.Colors.gradientPrimary)
                        .cornerRadius(6)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .font(AppTheme.Typography.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine(stroke: StrokeStyle(dash: [4]))
                            .foregroundStyle(AppTheme.Colors.separator)
                        AxisValueLabel()
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(AppTheme.Spacing.md)
        .surfaceCard()
    }
}

// MARK: - Activity Calendar

struct ActivityCalendarView: View {
    var sessions: [WorkoutSession]

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)
    private let dayLabels = ["月", "火", "水", "木", "金", "土", "日"]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "calendar.badge.checkmark")
                    .foregroundStyle(AppTheme.Colors.primary)
                Text("継続カレンダー")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }

            // 曜日ヘッダー
            HStack(spacing: 3) {
                ForEach(dayLabels, id: \.self) { day in
                    Text(day)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // カレンダーグリッド（直近28日）
            let dates = last28Days()
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(dates, id: \.self) { date in
                    let hasWorkout = sessions.contains { calendar.isDate($0.date, inSameDayAs: date) }
                    let isToday = calendar.isDateInToday(date)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(hasWorkout ? AppTheme.Colors.primary : AppTheme.Colors.surface2)
                        .frame(height: 32)
                        .overlay(
                            isToday ?
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(AppTheme.Colors.accent, lineWidth: 2)
                            : nil
                        )
                        .overlay(
                            Text(dateDay(date))
                                .font(AppTheme.Typography.monospacedSmall)
                                .foregroundStyle(hasWorkout ? .white : AppTheme.Colors.textSecondary)
                        )
                }
            }

            // 凡例
            HStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.Colors.primary)
                        .frame(width: 12, height: 12)
                    Text("ワークアウト済み")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(AppTheme.Colors.accent, lineWidth: 1.5)
                        .frame(width: 12, height: 12)
                    Text("今日")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .surfaceCard()
    }

    private func last28Days() -> [Date] {
        (0..<28).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: Date())
        }
    }

    private func dateDay(_ date: Date) -> String {
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }
}

// MARK: - Progress Empty State

struct ProgressEmptyStateView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            VStack(spacing: AppTheme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.primary.opacity(0.1))
                        .frame(width: 120, height: 120)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 52))
                        .foregroundStyle(AppTheme.Colors.primary)
                }

                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("まだ記録がありません")
                        .font(AppTheme.Typography.displaySmall)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text("ワークアウトを完了すると\nここに進捗グラフが表示されます")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    FirstStepRow(icon: "1.circle.fill", color: AppTheme.Colors.primary,
                                 text: "ホームタブで今日のメニューを確認")
                    FirstStepRow(icon: "2.circle.fill", color: AppTheme.Colors.success,
                                 text: "「ワークアウトを開始」をタップ")
                    FirstStepRow(icon: "3.circle.fill", color: AppTheme.Colors.accent,
                                 text: "完了すると進捗が記録されます")
                }
                .padding(AppTheme.Spacing.md)
                .surfaceCard()
                .padding(.horizontal, AppTheme.Spacing.lg)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FirstStepRow: View {
    var icon: String
    var color: Color
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 20))
                .frame(width: 24)
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Empty Chart Placeholder

struct EmptyChartPlaceholder: View {
    var message: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.5))
            Text(message)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}

#Preview {
    let vm = ProgressViewModel(agentManager: AgentManager())
    return ProgressAnalyticsView(viewModel: vm)
        .modelContainer(for: [UserProfile.self, WorkoutSession.self, WeeklyWorkoutPlan.self], inMemory: true)
}
