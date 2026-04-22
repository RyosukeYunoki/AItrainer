// WorkoutView.swift
// FitEvo
//
// ワークアウト実行画面。
// エージェントが生成した種目リストに従い、セット・レップをカウントする。

import SwiftUI
import SwiftData

// MARK: - WorkoutView

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @Bindable var viewModel: WorkoutViewModel
    var action: WorkoutAction
    var currentState: FitEvoState

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            if viewModel.isCompleted {
                WorkoutCompletionView(
                    reward: viewModel.earnedReward,
                    breakdown: viewModel.rewardBreakdown,
                    elapsedTime: viewModel.elapsedTimeFormatted,
                    completedExercises: viewModel.exercises.filter { $0.isCompleted }.count,
                    totalExercises: viewModel.exercises.count,
                    onDone: {
                        onComplete()
                        dismiss()
                    }
                )
            } else {
                VStack(spacing: 0) {
                    // ヘッダー
                    WorkoutHeader(
                        elapsedTime: viewModel.elapsedTimeFormatted,
                        progress: viewModel.progress,
                        onQuit: { dismiss() }
                    )

                    if viewModel.isResting {
                        // 休憩タイマー
                        RestTimerView(
                            timeRemaining: viewModel.restTimeRemaining,
                            onSkip: { viewModel.skipRest() }
                        )
                    } else {
                        ScrollView {
                            VStack(spacing: AppTheme.Spacing.md) {
                                // 現在の種目
                                if let exercise = viewModel.currentExercise {
                                    CurrentExerciseCard(
                                        exercise: exercise,
                                        currentSet: viewModel.currentSet,
                                        onComplete: { viewModel.completeSet() },
                                        onSkip: { viewModel.skipExercise() }
                                    )
                                }

                                // 種目リスト
                                ExerciseListView(
                                    exercises: viewModel.exercises,
                                    currentIndex: viewModel.currentExerciseIndex
                                )
                            }
                            .padding(AppTheme.Spacing.md)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.setupWorkout(action: action, profile: profiles.first)
        }
        .onChange(of: viewModel.isCompleted) { _, completed in
            if completed {
                // 完了時に報酬を計算してエージェントに学習させる
                var nextState = currentState
                nextState.consecutiveDays += 1
                nextState.daysSinceLastWorkout = 0
                viewModel.calculateAndLearnReward(
                    state: currentState,
                    nextState: nextState,
                    modelContext: modelContext
                )
            }
        }
    }
}

// MARK: - Header

struct WorkoutHeader: View {
    var elapsedTime: String
    var progress: Double
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack {
                Button(action: onQuit) {
                    Image(systemName: "xmark")
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppTheme.Colors.surface))
                }

                Spacer()

                Text(elapsedTime)
                    .font(AppTheme.Typography.monospacedLarge)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(AppTheme.Typography.monospaced)
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 36)
            }

            // 進捗バー
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.Colors.surface2)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.Colors.gradientPrimary)
                        .frame(width: geo.size.width * progress, height: 4)
                        .animation(AppTheme.Animation.standard, value: progress)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.md)
        .padding(.bottom, AppTheme.Spacing.sm)
        .background(AppTheme.Colors.background)
    }
}

// MARK: - Current Exercise Card

struct CurrentExerciseCard: View {
    var exercise: WorkoutExercise
    var currentSet: Int
    var onComplete: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // 種目名
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(exercise.exercise.name)
                    .font(AppTheme.Typography.displayMedium)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(exercise.exercise.description)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            // セット・レップ表示
            HStack(spacing: AppTheme.Spacing.xl) {
                VStack(spacing: 4) {
                    Text("\(currentSet)")
                        .font(.system(size: 56, design: .monospaced).weight(.bold))
                        .foregroundStyle(AppTheme.Colors.primary)
                    Text("/ \(exercise.sets) セット")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Divider()
                    .frame(height: 60)
                    .background(AppTheme.Colors.separator)

                VStack(spacing: 4) {
                    Text("\(exercise.reps)")
                        .font(.system(size: 56, design: .monospaced).weight(.bold))
                        .foregroundStyle(AppTheme.Colors.accent)
                    Text("回")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }

            // 難易度・筋群
            HStack(spacing: AppTheme.Spacing.sm) {
                Label(exercise.exercise.equipmentEnum.displayName, systemImage: exercise.exercise.equipmentEnum.icon)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                Spacer()

                Text(exercise.exercise.difficultyText)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.warning)
            }

            // ボタン
            VStack(spacing: AppTheme.Spacing.sm) {
                Button(action: onComplete) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("セット完了")
                            .font(AppTheme.Typography.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .fill(AppTheme.Colors.gradientPrimary)
                    )
                }

                Button(action: onSkip) {
                    Text("スキップ")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .surfaceCard()
    }
}

// MARK: - Rest Timer

struct RestTimerView: View {
    var timeRemaining: Int
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            Text("休憩中")
                .font(AppTheme.Typography.displaySmall)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            ZStack {
                Circle()
                    .stroke(AppTheme.Colors.surface2, lineWidth: 12)
                    .frame(width: 200, height: 200)

                Text("\(timeRemaining)")
                    .font(.system(size: 72, design: .monospaced).weight(.bold))
                    .foregroundStyle(AppTheme.Colors.primary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut, value: timeRemaining)
            }

            Text("次のセットまで待機してください")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Button(action: onSkip) {
                Text("スキップ →")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.primary)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(
                        Capsule().stroke(AppTheme.Colors.primary, lineWidth: 1.5)
                    )
            }

            Spacer()
        }
    }
}

// MARK: - Exercise List

struct ExerciseListView: View {
    var exercises: [WorkoutExercise]
    var currentIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("種目リスト")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
            }

            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                ExerciseRowView(
                    exercise: exercise,
                    index: index + 1,
                    isCurrent: index == currentIndex,
                    isCompleted: exercise.isCompleted
                )
            }
        }
    }
}

struct ExerciseRowView: View {
    var exercise: WorkoutExercise
    var index: Int
    var isCurrent: Bool
    var isCompleted: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // 番号・状態
            ZStack {
                Circle()
                    .fill(isCompleted ? AppTheme.Colors.success :
                          isCurrent ? AppTheme.Colors.primary :
                          AppTheme.Colors.surface2)
                    .frame(width: 32, height: 32)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(index)")
                        .font(AppTheme.Typography.monospacedSmall)
                        .foregroundStyle(isCurrent ? .white : AppTheme.Colors.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exercise.name)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(isCompleted ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary)
                    .strikethrough(isCompleted)

                Text("\(exercise.sets)セット × \(exercise.reps)回")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Spacer()

            // 完了セット数
            if !isCompleted && isCurrent {
                Text("\(exercise.completedSets)/\(exercise.sets)")
                    .font(AppTheme.Typography.monospacedSmall)
                    .foregroundStyle(AppTheme.Colors.primary)
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                .fill(isCurrent ? AppTheme.Colors.primary.opacity(0.08) : AppTheme.Colors.surface)
        )
        .animation(AppTheme.Animation.standard, value: isCurrent)
    }
}

// MARK: - Completion View

struct WorkoutCompletionView: View {
    var reward: Double
    var breakdown: RewardBreakdown?
    var elapsedTime: String
    var completedExercises: Int
    var totalExercises: Int
    var onDone: () -> Void

    @State private var showBreakdown = false
    @State private var animateReward = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // 完了アニメーション
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.gradientSuccess)
                        .frame(width: 120, height: 120)
                        .opacity(0.2)
                        .scaleEffect(animateReward ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateReward)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(AppTheme.Colors.gradientSuccess)
                }
                .padding(.top, AppTheme.Spacing.xl)

                Text("ワークアウト完了!")
                    .font(AppTheme.Typography.displayMedium)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                // AIフィードバック
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("AIエージェントが学習しました")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.accent)

                    HStack(spacing: 4) {
                        Image(systemName: "brain.fill")
                            .foregroundStyle(AppTheme.Colors.accent)
                        Text(String(format: "獲得報酬: %+.3f", reward))
                            .font(AppTheme.Typography.monospaced)
                            .foregroundStyle(reward >= 0 ? AppTheme.Colors.success : AppTheme.Colors.warning)
                    }
                    .font(AppTheme.Typography.displaySmall)
                }
                .padding(AppTheme.Spacing.md)
                .surfaceCard()

                // サマリー
                HStack(spacing: AppTheme.Spacing.xl) {
                    VStack(spacing: 4) {
                        Text(elapsedTime)
                            .font(AppTheme.Typography.monospacedLarge)
                            .foregroundStyle(AppTheme.Colors.primary)
                        Text("時間")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    VStack(spacing: 4) {
                        Text("\(completedExercises)/\(totalExercises)")
                            .font(AppTheme.Typography.monospacedLarge)
                            .foregroundStyle(AppTheme.Colors.success)
                        Text("完了種目")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }

                // 報酬内訳（折りたたみ）
                if let breakdown = breakdown {
                    DisclosureGroup(
                        isExpanded: $showBreakdown,
                        content: {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                RewardRow(label: "目標進捗 (α=0.4)", value: breakdown.progressComponent, color: AppTheme.Colors.primary)
                                RewardRow(label: "継続ボーナス (β=0.3)", value: breakdown.consistencyComponent, color: AppTheme.Colors.success)
                                RewardRow(label: "過学習ペナルティ (γ=0.2)", value: -breakdown.penaltyComponent, color: AppTheme.Colors.danger)
                                RewardRow(label: "適応ボーナス (δ=0.1)", value: breakdown.adaptationComponent, color: AppTheme.Colors.warning)
                                Divider().background(AppTheme.Colors.separator)
                                RewardRow(label: "合計報酬", value: breakdown.total, color: AppTheme.Colors.textPrimary)
                                    .font(AppTheme.Typography.headline)
                            }
                            .padding(.top, AppTheme.Spacing.sm)
                        },
                        label: {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundStyle(AppTheme.Colors.accent)
                                Text("報酬関数の内訳")
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                            }
                        }
                    )
                    .padding(AppTheme.Spacing.md)
                    .surfaceCard()
                }

                Button(action: onDone) {
                    Text("ダッシュボードに戻る")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .fill(AppTheme.Colors.gradientPrimary)
                        )
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .onAppear {
            withAnimation { animateReward = true }
        }
    }
}

struct RewardRow: View {
    var label: String
    var value: Double
    var color: Color
    var font: Font = AppTheme.Typography.monospaced

    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Spacer()
            Text(String(format: "%+.3f", value))
                .font(font)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    let agent = AgentManager()
    let vm = WorkoutViewModel(agentManager: agent)
    return WorkoutView(
        viewModel: vm,
        action: WorkoutAction.standardWorkout(focusAreas: [.chest, .arms]),
        currentState: .mock,
        onComplete: {}
    )
    .modelContainer(for: [UserProfile.self, WorkoutSession.self, WeeklyWorkoutPlan.self], inMemory: true)
}
