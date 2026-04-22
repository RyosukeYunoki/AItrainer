// DashboardView.swift
// FitEvo
//
// メインダッシュボード画面。
// エージェントの推奨・生体データ・週次進捗を一覧表示する。

import SwiftUI
import SwiftData

// MARK: - DashboardView

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @AppStorage("fitevo_agent_messages_enabled") private var agentMessagesEnabled: Bool = true

    @Bindable var viewModel: DashboardViewModel
    var onStartWorkout: (WorkoutAction) -> Void

    var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {

                        // ヘッダー（日付）
                        DashboardHeaderView(
                            date: viewModel.formattedDate,
                            dayOfWeek: viewModel.todayDayOfWeek
                        )

                        // AIメッセージバナー
                        if agentMessagesEnabled && viewModel.showAgentMessage {
                            AgentMessageBanner(
                                message: viewModel.agentMessage,
                                onDismiss: {
                                    withAnimation(AppTheme.Animation.standard) {
                                        viewModel.showAgentMessage = false
                                    }
                                }
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // ① 今日やること（最重要 — 一番上に）
                        TodayRecommendationCard(
                            action: viewModel.todayAction,
                            reasoning: viewModel.todayReasoning,
                            onStart: { onStartWorkout(viewModel.todayAction) }
                        )

                        // ② 週次進捗（モチベーション）
                        WeeklyProgressCard(
                            completionRate: viewModel.weeklyCompletionRate,
                            streakDays: viewModel.streakDays
                        )

                        // ③ 今日の調子を入力（推奨に反映される）
                        FatigueSliderCard(
                            fatigue: $viewModel.subjectiveFatigue,
                            onChange: viewModel.updateFatigue
                        )

                        // ④ 生体データ（参考情報）
                        HealthSummaryCard(
                            heartRate: viewModel.rawHeartRate,
                            sleepHours: viewModel.rawSleepHours,
                            stepCount: viewModel.rawStepCount,
                            isConnected: viewModel.isHealthKitConnected
                        )

                        // ⑤ 今週のプレビュー
                        WeeklyPlanPreview(weeklyPlan: viewModel.weeklyPlan)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("ホーム")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(AppTheme.Colors.primary)
                    }
                }
            }
            .task {
                await viewModel.loadDashboard(profile: profile)
            }
        }
    }
}

// MARK: - Agent Message Banner

struct AgentMessageBanner: View {
    var message: String
    var onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            // マスコット（アニメーション付き）
            FitEvoMascot(size: 40)
                .scaleEffect(appeared ? 1.0 : 0.6)

            VStack(alignment: .leading, spacing: 4) {
                Text("FitEvo AI")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.primary)
                Text(message)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .padding(6)
                    .background(Circle().fill(AppTheme.Colors.surface2))
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .stroke(AppTheme.Colors.primary.opacity(0.25), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(AppTheme.Animation.standard.delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Header

struct DashboardHeaderView: View {
    var date: String
    var dayOfWeek: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dayOfWeek)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                Text(date)
                    .font(AppTheme.Typography.displaySmall)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            Spacer()
        }
        .padding(.top, AppTheme.Spacing.sm)
    }
}

// MARK: - Fatigue Slider

struct FatigueSliderCard: View {
    @Binding var fatigue: Int
    var onChange: (Int) -> Void

    private let labels = ["非常に元気", "元気", "普通", "疲れ気味", "非常に疲れている"]
    private let colors: [Color] = [.green, Color(hex: "84cc16"), AppTheme.Colors.warning, Color(hex: "f97316"), AppTheme.Colors.danger]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .foregroundStyle(AppTheme.Colors.primary)
                Text("今日の調子は？")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                Text(labels[fatigue - 1])
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(colors[fatigue - 1])
                    .animation(AppTheme.Animation.standard, value: fatigue)
            }

            HStack(spacing: AppTheme.Spacing.xs) {
                ForEach(1...5, id: \.self) { level in
                    Button(action: {
                        fatigue = level
                        onChange(level)
                    }) {
                        Circle()
                            .fill(level <= fatigue ? colors[fatigue - 1] : AppTheme.Colors.surface2)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text("\(level)")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(level <= fatigue ? .white : AppTheme.Colors.textSecondary)
                            )
                    }
                    .animation(AppTheme.Animation.standard, value: fatigue)

                    if level < 5 { Spacer() }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .surfaceCard()
    }
}

// MARK: - Today Recommendation

struct TodayRecommendationCard: View {
    var action: WorkoutAction
    var reasoning: String
    var onStart: () -> Void

    private let cardGradient = LinearGradient(
        colors: [Color(hex: "1D4ED8"), Color(hex: "2563EB"), Color(hex: "4F46E5")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {

            // ヘッダー
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("今日のAI推奨")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.3)
                }
                .foregroundStyle(.white.opacity(0.9))

                Spacer()

                // 強度バッジ（白ベース）
                IntensityBadgeLight(intensity: action.intensity)
            }

            if action.restDay {
                // 休息日
                HStack(spacing: AppTheme.Spacing.md) {
                    Text("🌙")
                        .font(.system(size: 40))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("今日は休息日")
                            .font(AppTheme.Typography.displaySmall)
                            .foregroundStyle(.white)
                        Text("しっかり回復して明日に備えましょう")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            } else {
                // ワークアウト推奨
                HStack(spacing: AppTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(action.duration)")
                            .font(.system(size: 48, design: .monospaced).weight(.bold))
                            .foregroundStyle(.white)
                        Text("分")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Rectangle()
                        .fill(.white.opacity(0.25))
                        .frame(width: 1)
                        .frame(height: 50)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(action.focusAreaDisplayName)
                            .font(AppTheme.Typography.displaySmall)
                            .foregroundStyle(.white)
                        Text("\(action.exerciseCount)種目")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()
                }
            }

            // AIの判断根拠
            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 1)
                Text(reasoning)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                    .fill(.white.opacity(0.12))
            )

            if !action.restDay {
                Button(action: onStart) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("ワークアウトを開始")
                            .font(AppTheme.Typography.headline)
                    }
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                            .fill(.white)
                    )
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(cardGradient)
                .shadow(color: Color(hex: "2563EB").opacity(0.4), radius: 20, x: 0, y: 8)
        )
    }
}

// MARK: - Intensity Badge (Light / for dark background)

struct IntensityBadgeLight: View {
    var intensity: WorkoutIntensity

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: intensity.icon)
            Text(intensity.displayName)
        }
        .font(AppTheme.Typography.caption)
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(.white.opacity(0.2))
        )
    }
}

// MARK: - Intensity Badge

struct IntensityBadge: View {
    var intensity: WorkoutIntensity

    var color: Color {
        switch intensity {
        case .rest:     return AppTheme.Colors.accent
        case .light:    return AppTheme.Colors.success
        case .moderate: return AppTheme.Colors.warning
        case .hard:     return AppTheme.Colors.danger
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: intensity.icon)
            Text(intensity.displayName)
        }
        .font(AppTheme.Typography.caption)
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(color.opacity(0.15))
        )
    }
}

// MARK: - Weekly Progress Card

struct WeeklyProgressCard: View {
    var completionRate: Double
    var streakDays: Int

    private var progressColor: Color {
        switch completionRate {
        case 0.8...: return AppTheme.Colors.success
        case 0.5...: return AppTheme.Colors.primary
        default:     return AppTheme.Colors.warning
        }
    }

    private var statusLabel: String {
        switch completionRate {
        case 0.8...: return "絶好調！"
        case 0.5...: return "順調です"
        case 0.01...: return "頑張ろう"
        default:     return "記録なし"
        }
    }

    private var streakMessage: String {
        if streakDays >= 7 { return "1週間達成！" }
        if streakDays >= 3 { return "いい調子！" }
        return "継続しよう"
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {

            // ── 単一ドーナツリング ──
            ZStack {
                ProgressRing(progress: completionRate, color: progressColor, lineWidth: 13, size: 96)
                VStack(spacing: 0) {
                    Text("\(Int(completionRate * 100))")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundStyle(progressColor)
                    Text("%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }

            // ── 右側テキスト情報 ──
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {

                VStack(alignment: .leading, spacing: 3) {
                    Text("今週の達成率")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    Text(statusLabel)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(progressColor)
                }

                Divider()

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text("\(streakDays)")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(streakDays >= 3 ? AppTheme.Colors.success : AppTheme.Colors.textPrimary)
                        Text("日連続")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    Text(streakMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .surfaceCard()
    }
}

struct StatRow: View {
    var label: String
    var value: String
    var color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.monospaced)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Weekly Plan Preview

struct WeeklyPlanPreview: View {
    var weeklyPlan: [WorkoutAction]

    private let dayLabels = ["月", "火", "水", "木", "金", "土", "日"]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(AppTheme.Colors.primary)
                Text("今週のAIプラン")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
            }

            HStack(spacing: AppTheme.Spacing.xs) {
                ForEach(Array(weeklyPlan.prefix(7).enumerated()), id: \.offset) { index, action in
                    VStack(spacing: 6) {
                        Text(index < dayLabels.count ? dayLabels[index] : "-")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)

                        ZStack {
                            Circle()
                                .fill(dayColor(action).opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: action.restDay ? "moon.zzz" : action.intensity.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(dayColor(action))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .surfaceCard()
    }

    func dayColor(_ action: WorkoutAction) -> Color {
        switch action.intensity {
        case .rest:     return AppTheme.Colors.textSecondary
        case .light:    return AppTheme.Colors.success
        case .moderate: return AppTheme.Colors.warning
        case .hard:     return AppTheme.Colors.danger
        }
    }
}

#Preview {
    let agentManager = AgentManager()
    let healthManager = HealthKitManager()
    let vm = DashboardViewModel(agentManager: agentManager, healthKitManager: healthManager)
    vm.weeklyPlan = Array(repeating: WorkoutAction.standardWorkout(focusAreas: [.chest]), count: 7)

    return DashboardView(viewModel: vm, onStartWorkout: { _ in })
        .modelContainer(for: [UserProfile.self, WorkoutSession.self, WeeklyWorkoutPlan.self], inMemory: true)
}
