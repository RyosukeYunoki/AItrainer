// SettingsView.swift
// FitEvo
//
// 設定画面。専門用語を使わず、すべてのユーザーが直感的に操作できる設計。

import SwiftUI
import SwiftData

// MARK: - SettingsView

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Bindable var agentManager: AgentManager

    @State private var showResetConfirmation = false
    @State private var showAbout = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                List {
                    // AIモード選択
                    AIModeSection(agentManager: agentManager)

                    // AIのバランス調整
                    AIBalanceSection(params: $agentManager.rewardParameters, agentManager: agentManager)

                    // AIの学習スピード調整
                    AILearningSpeedSection(params: $agentManager.learningParameters, agentManager: agentManager)

                    // ヘルスケア連携
                    HealthKitSection()

                    // AIメッセージ設定
                    AgentMessageSection()

                    // アプリについて
                    AboutSection(showAbout: $showAbout)

                    // データ管理
                    DataManagementSection(onReset: { showResetConfirmation = true })

                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
            .navigationDestination(isPresented: $showAbout) {
                AboutView()
            }
            .alert("AIをリセットしますか？", isPresented: $showResetConfirmation) {
                Button("リセット", role: .destructive) {
                    agentManager.resetAll()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("AIがこれまで学習したデータがすべて消去されます。最初からやり直したいときに使ってください。")
            }
        }
    }
}

// MARK: - AIモード選択

struct AIModeSection: View {
    @Bindable var agentManager: AgentManager

    var body: some View {
        Section {
            ForEach(AlgorithmType.allCases, id: \.rawValue) { type in
                AIModeRow(
                    type: type,
                    isSelected: agentManager.algorithmType == type,
                    onSelect: { agentManager.switchAlgorithm(to: type) }
                )
            }
        } header: {
            SectionHeader(title: "AIのモード", icon: "cpu")
        } footer: {
            Text("モードによってAIの提案の仕方が変わります。迷ったら「学習型AI」がおすすめです。")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .listRowBackground(AppTheme.Colors.surface)
    }
}

struct AIModeRow: View {
    var type: AlgorithmType
    var isSelected: Bool
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.Colors.primary.opacity(0.15) : AppTheme.Colors.surface2)
                        .frame(width: 40, height: 40)
                    Image(systemName: type.icon)
                        .foregroundStyle(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(type.algorithmDescription)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.Colors.primary)
                        .font(.system(size: 20))
                }
            }
            .padding(.vertical, AppTheme.Spacing.xs)
        }
        .animation(AppTheme.Animation.standard, value: isSelected)
    }
}

// MARK: - AIのバランス調整

/// 報酬関数パラメータを専門用語なしで調整するセクション
struct AIBalanceSection: View {
    @Binding var params: RewardParameters
    var agentManager: AgentManager

    var body: some View {
        Section {
            FriendlySlider(
                label: "目標への集中度",
                icon: "target",
                value: $params.alpha,
                lowLabel: "バランス重視",
                highLabel: "目標集中"
            )
            FriendlySlider(
                label: "続けやすさの重視",
                icon: "calendar.badge.checkmark",
                value: $params.beta,
                lowLabel: "強度優先",
                highLabel: "継続優先"
            )
            FriendlySlider(
                label: "疲労への敏感さ",
                icon: "waveform.path.ecg",
                value: $params.gamma,
                lowLabel: "プッシュ寄り",
                highLabel: "休養重視"
            )
            FriendlySlider(
                label: "回復サイクルの重視",
                icon: "arrow.clockwise.heart",
                value: $params.delta,
                lowLabel: "強度優先",
                highLabel: "回復優先"
            )

            Button(action: { agentManager.rewardParameters = params }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("この設定を反映する")
                }
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.primary)
            }

        } header: {
            SectionHeader(title: "AIの優先事項", icon: "slider.horizontal.3")
        } footer: {
            Text("AIがトレーニングを提案するときに何を重視するかを調整します。変更すると次回の提案から反映されます。")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .listRowBackground(AppTheme.Colors.surface)
    }
}

// MARK: - AIの学習スピード

/// 学習パラメータを専門用語なしで調整するセクション
struct AILearningSpeedSection: View {
    @Binding var params: LearningParameters
    var agentManager: AgentManager

    var body: some View {
        Section {
            FriendlySlider(
                label: "新しい情報への適応速度",
                icon: "bolt.fill",
                value: $params.learningRate,
                lowLabel: "ゆっくり慎重に",
                highLabel: "すばやく反映"
            )
            FriendlySlider(
                label: "長期的な視野",
                icon: "eye",
                value: $params.discountFactor,
                lowLabel: "今だけ重視",
                highLabel: "先を見据える"
            )
            FriendlySlider(
                label: "新しいメニューへの挑戦度",
                icon: "dice",
                value: $params.explorationRate,
                lowLabel: "実績のある提案",
                highLabel: "新しい提案を試す"
            )

            Button(action: {
                agentManager.learningParameters = params
                agentManager.applyLearningParameters()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("この設定を反映する")
                }
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.primary)
            }

        } header: {
            SectionHeader(title: "AIの学習スタイル", icon: "graduationcap")
        } footer: {
            Text("AIがどのように学習を進めるかを調整します。迷ったらデフォルトのままで大丈夫です。")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .listRowBackground(AppTheme.Colors.surface)
    }
}

// MARK: - わかりやすいスライダー

struct FriendlySlider: View {
    var label: String
    var icon: String
    @Binding var value: Double
    var lowLabel: String
    var highLabel: String

    private var levelText: String {
        switch value {
        case 0..<0.2:  return "かなり低め"
        case 0.2..<0.4: return "低め"
        case 0.4..<0.6: return "標準"
        case 0.6..<0.8: return "高め"
        default:        return "かなり高め"
        }
    }

    private var levelColor: Color {
        switch value {
        case 0..<0.3: return AppTheme.Colors.textSecondary
        case 0.3..<0.7: return AppTheme.Colors.primary
        default:       return AppTheme.Colors.accent
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 20)
                Text(label)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                Text(levelText)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(levelColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(levelColor.opacity(0.12)))
                    .animation(AppTheme.Animation.standard, value: levelText)
            }

            Slider(value: $value, in: 0...1, step: 0.05)
                .tint(AppTheme.Colors.primary)

            HStack {
                Text(lowLabel)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                Spacer()
                Text(highLabel)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

// MARK: - AIメッセージ設定

struct AgentMessageSection: View {
    @AppStorage("fitevo_agent_messages_enabled") private var enabled: Bool = true

    var body: some View {
        Section {
            Toggle(isOn: $enabled) {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "message.fill")
                        .foregroundStyle(AppTheme.Colors.primary)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AIからの一言")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Text("アプリを開いたときにAIが状態に応じてメッセージを表示します")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
            }
            .tint(AppTheme.Colors.primary)
        } header: {
            SectionHeader(title: "AIメッセージ", icon: "message.fill")
        }
        .listRowBackground(AppTheme.Colors.surface)
    }
}

// MARK: - HealthKit Section

struct HealthKitSection: View {
    var body: some View {
        Section {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(AppTheme.Colors.danger)
                    .font(.system(size: 22))

                VStack(alignment: .leading, spacing: 4) {
                    Text("ヘルスケアアプリとの連携")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text("連携の変更は「設定」→「プライバシーとセキュリティ」→「ヘルスケア」→「FitEvo」から行えます")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        } header: {
            SectionHeader(title: "ヘルスケア連携", icon: "heart.fill")
        } footer: {
            Text("心拍数・睡眠・歩数などのデータはAIがより良い提案をするために使用します。すべてのデータはこの端末内だけで処理されます。")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .listRowBackground(AppTheme.Colors.surface)
    }
}

// MARK: - About Section

struct AboutSection: View {
    @Binding var showAbout: Bool

    var body: some View {
        Section {
            Button(action: { showAbout = true }) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(AppTheme.Colors.primary)
                    Text("このアプリについて")
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .font(.caption)
                }
            }
        } header: {
            SectionHeader(title: "サポート", icon: "questionmark.circle")
        }
        .listRowBackground(AppTheme.Colors.surface)
    }
}

// MARK: - データ管理

struct DataManagementSection: View {
    var onReset: () -> Void

    var body: some View {
        Section {
            Button(action: onReset) {
                HStack {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .foregroundStyle(AppTheme.Colors.danger)
                    Text("AIをはじめからやり直す")
                        .foregroundStyle(AppTheme.Colors.danger)
                }
            }
        } header: {
            SectionHeader(title: "データ管理", icon: "externaldrive")
        } footer: {
            Text("AIがこれまでに学習したデータをすべて消去します。提案の精度が初期状態に戻ります。")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .listRowBackground(AppTheme.Colors.surface)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    var title: String
    var icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.Colors.primary)
            Text(title)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .font(AppTheme.Typography.caption)
        .textCase(nil)
    }
}


#Preview {
    SettingsView(agentManager: AgentManager())
        .modelContainer(for: [UserProfile.self, WorkoutSession.self, WeeklyWorkoutPlan.self], inMemory: true)
}
