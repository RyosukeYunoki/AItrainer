// OnboardingView.swift
// FitEvo
//
// オンボーディング画面。
// ユーザーの目標・レベル・設定を収集し、初回エージェントを設定する。

import SwiftUI
import SwiftData

// MARK: - OnboardingView

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: OnboardingViewModel

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            // 背景グラデーション効果
            RadialGradient(
                colors: [AppTheme.Colors.accent.opacity(0.15), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // プログレスバー
                OnboardingProgressBar(currentStep: viewModel.currentStep, totalSteps: 7)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.lg)

                // ページコンテンツ（キーボードで押し上げられてテキストフィールドが見える）
                TabView(selection: $viewModel.currentStep) {
                    WelcomeStepView().tag(0)
                    NameStepView(userName: $viewModel.userName).tag(1)
                    GoalStepView(selectedGoal: $viewModel.selectedGoal).tag(2)
                    LevelStepView(selectedLevel: $viewModel.selectedLevel).tag(3)
                    BodyMeasurementStepView(
                        weight: $viewModel.currentWeight,
                        height: $viewModel.height
                    ).tag(4)
                    WorkoutDaysStepView(workoutDays: $viewModel.weeklyWorkoutDays).tag(5)
                    EquipmentStepView(
                        selectedEquipment: $viewModel.selectedEquipment,
                        onHealthKitRequest: {
                            Task { await viewModel.requestHealthKit() }
                        }
                    ).tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)
            }

            // ナビゲーションボタン（キーボードを無視して常に画面下部に固定）
            VStack {
                Spacer()
                OnboardingNavigationButtons(
                    currentStep: viewModel.currentStep,
                    totalSteps: 7,
                    canProceed: viewModel.canProceed,
                    onBack: { viewModel.goBack() },
                    onNext: {
                        if viewModel.currentStep == 6 {
                            viewModel.completeOnboarding(modelContext: modelContext)
                            onComplete()
                        } else {
                            viewModel.goNext()
                        }
                    }
                )
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xl)
                .background(
                    // ボタンがコンテンツに重なったとき読みやすくするためのグラデーション
                    LinearGradient(
                        colors: [AppTheme.Colors.background.opacity(0), AppTheme.Colors.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}

// MARK: - Progress Bar

struct OnboardingProgressBar: View {
    var currentStep: Int
    var totalSteps: Int

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(0..<totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step <= currentStep ? AppTheme.Colors.primary : AppTheme.Colors.surface2)
                    .frame(height: 4)
                    .animation(AppTheme.Animation.standard, value: currentStep)
            }
        }
    }
}

// MARK: - Step 0: Welcome

struct WelcomeStepView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 24
    @State private var cardOpacity: Double = 0
    @State private var rowOpacities: [Double] = [0, 0, 0, 0]

    private let features: [(String, String)] = [
        ("heart.fill",        "心拍・睡眠・歩数でコンディションを自動判定"),
        ("brain",             "AIが毎日最適なメニューを提案"),
        ("bolt.fill",         "続けるほどあなたの身体に合った提案に"),
        ("lock.shield.fill",  "データはすべてこの端末内で処理。外部送信なし")
    ]

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            // ── マスコット（バウンスイン＋パルス）──
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.primary.opacity(0.07))
                    .frame(width: 170, height: 170)
                    .scaleEffect(pulseScale)

                FitEvoMascot(size: 110, showAnimation: true)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
            }

            // ── タイトル（スライドアップ）──
            VStack(spacing: AppTheme.Spacing.xs) {
                Text("FitEvo")
                    .font(AppTheme.Typography.displayLarge)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text("AIがあなたの専属\nフィットネスコーチに")
                    .font(AppTheme.Typography.displaySmall)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(titleOpacity)
            .offset(y: titleOffset)

            // ── 機能一覧（ステガー表示）──
            VStack(spacing: AppTheme.Spacing.md) {
                ForEach(Array(features.enumerated()), id: \.offset) { i, item in
                    FeatureRow(icon: item.0, text: item.1)
                        .opacity(rowOpacities[i])
                }
            }
            .padding(AppTheme.Spacing.lg)
            .surfaceCard()
            .padding(.horizontal, AppTheme.Spacing.lg)
            .opacity(cardOpacity)

            Spacer()
        }
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        // ロゴ バウンスイン
        withAnimation(.spring(response: 0.55, dampingFraction: 0.58)) {
            logoScale   = 1.0
            logoOpacity = 1.0
        }
        // ロゴ パルス（無限ループ）
        withAnimation(
            .easeInOut(duration: 1.6)
            .repeatForever(autoreverses: true)
            .delay(0.5)
        ) {
            pulseScale = 1.14
        }
        // タイトル スライドアップ
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            titleOpacity = 1.0
            titleOffset  = 0
        }
        // カード フェードイン
        withAnimation(.easeOut(duration: 0.4).delay(0.55)) {
            cardOpacity = 1.0
        }
        // 各行ステガー
        for i in 0..<4 {
            withAnimation(.easeOut(duration: 0.35).delay(0.65 + Double(i) * 0.1)) {
                rowOpacities[i] = 1.0
            }
        }
    }
}

struct FeatureRow: View {
    var icon: String
    var text: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.Colors.primary)
                .frame(width: 24)
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Spacer()
        }
    }
}

// MARK: - Step 1: Name

struct NameStepView: View {
    @Binding var userName: String
    @FocusState private var isFocused: Bool

    private let fullMessage = "はじめまして！\nあなたの専属AIトレーナーです。\n\nどうぞよろしくお願いします。\nあなたのことを、なんとお呼びすれば\nよいでしょうか？"
    @State private var displayedText = ""
    @State private var charIndex = 0
    @State private var typingDone = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer().frame(height: AppTheme.Spacing.xl)

                // AI アバター（マスコット）
                FitEvoMascot(size: 80, showAnimation: true)

                // AI の吹き出し
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack(spacing: 6) {
                        Text("FitEvo AI")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.Colors.primary)
                        Circle()
                            .fill(AppTheme.Colors.success)
                            .frame(width: 6, height: 6)
                        Spacer()
                        // タイピング中インジケーター
                        if !typingDone {
                            HStack(spacing: 3) {
                                ForEach(0..<3) { i in
                                    Circle()
                                        .fill(AppTheme.Colors.textSecondary.opacity(0.5))
                                        .frame(width: 5, height: 5)
                                        .offset(y: typingDone ? 0 : -2)
                                        .animation(
                                            .easeInOut(duration: 0.4)
                                            .repeatForever()
                                            .delay(Double(i) * 0.13),
                                            value: typingDone
                                        )
                                }
                            }
                        }
                    }

                    // タイプライター テキスト
                    Text(displayedText)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 120, alignment: .topLeading)
                }
                .padding(AppTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .fill(AppTheme.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .stroke(AppTheme.Colors.primary.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, AppTheme.Spacing.lg)

                // 名前入力（タイピング完了後にフェードイン）
                VStack(spacing: AppTheme.Spacing.sm) {
                    TextField("名前を入力してください", text: $userName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit { isFocused = false }
                        .padding(.vertical, AppTheme.Spacing.md)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .fill(AppTheme.Colors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                        .stroke(
                                            isFocused ? AppTheme.Colors.primary : AppTheme.Colors.separator,
                                            lineWidth: isFocused ? 2 : 1
                                        )
                                )
                        )
                        .animation(AppTheme.Animation.standard, value: isFocused)

                    if !userName.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("こんにちは、\(userName.trimmingCharacters(in: .whitespaces))さん！")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.primary)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .animation(AppTheme.Animation.standard, value: userName)
                .opacity(typingDone ? 1 : 0)

                // ナビゲーションボタン分の余白
                Spacer().frame(height: 100)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        // 背景タップでキーボードを閉じる
        .contentShape(Rectangle())
        .onTapGesture { isFocused = false }
        .onAppear {
            startTypewriter()
        }
    }

    private func startTypewriter() {
        displayedText = ""
        charIndex = 0
        typeNextChar(after: 0.6)
    }

    private func typeNextChar(after delay: Double) {
        let chars = Array(fullMessage)
        guard charIndex < chars.count else {
            typingDone = true
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let ch = chars[charIndex]
            displayedText += String(ch)
            charIndex += 1
            // 句読点・改行後は少し間を置く
            let next: Double
            switch ch {
            case "！", "。", "、": next = 0.18
            case "\n":            next = 0.22
            default:              next = 0.045
            }
            typeNextChar(after: next)
        }
    }
}

// MARK: - Step 2: Goal

struct GoalStepView: View {
    @Binding var selectedGoal: FitnessGoal

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            OnboardingStepHeader(
                title: "目標を選んでください",
                subtitle: "AIエージェントがあなたの目標に\n合わせて最適化します"
            )

            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(FitnessGoal.allCases, id: \.rawValue) { goal in
                    GoalOptionCard(
                        goal: goal,
                        isSelected: selectedGoal == goal,
                        onTap: { selectedGoal = goal }
                    )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)

            Spacer()
        }
    }
}

struct GoalOptionCard: View {
    var goal: FitnessGoal
    var isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: goal.icon)
                    .foregroundStyle(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                    .font(.system(size: 22))
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.displayName)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(goal.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.Colors.primary)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(isSelected ? AppTheme.Colors.primary.opacity(0.1) : AppTheme.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .stroke(isSelected ? AppTheme.Colors.primary : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .animation(AppTheme.Animation.standard, value: isSelected)
    }
}

// MARK: - Step 2: Level

struct LevelStepView: View {
    @Binding var selectedLevel: FitnessLevel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            OnboardingStepHeader(
                title: "フィットネスレベルは？",
                subtitle: "現在の運動経験を教えてください"
            )

            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(FitnessLevel.allCases, id: \.rawValue) { level in
                    LevelOptionCard(
                        level: level,
                        isSelected: selectedLevel == level,
                        onTap: { selectedLevel = level }
                    )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)

            Spacer()
        }
    }
}

struct LevelOptionCard: View {
    var level: FitnessLevel
    var isSelected: Bool
    var onTap: () -> Void

    var levelColor: Color {
        switch level {
        case .beginner:     return AppTheme.Colors.success
        case .intermediate: return AppTheme.Colors.warning
        case .advanced:     return AppTheme.Colors.danger
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(levelColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(level == .beginner ? "🌱" : level == .intermediate ? "💪" : "🔥")
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(level.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(levelColor)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(isSelected ? levelColor.opacity(0.08) : AppTheme.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .stroke(isSelected ? levelColor : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .animation(AppTheme.Animation.standard, value: isSelected)
    }
}

// MARK: - Step 3: Body Measurement

struct BodyMeasurementStepView: View {
    @Binding var weight: Double  // kg
    @Binding var height: Double  // cm

    var bmi: Double {
        let h = height / 100
        guard h > 0 else { return 0 }
        return weight / (h * h)
    }

    var bmiLabel: (text: String, color: Color) {
        switch bmi {
        case ..<18.5: return ("低体重", AppTheme.Colors.warning)
        case 18.5..<25: return ("標準", AppTheme.Colors.success)
        case 25..<30: return ("過体重", AppTheme.Colors.warning)
        default: return ("肥満", AppTheme.Colors.danger)
        }
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            OnboardingStepHeader(
                title: "体型を教えてください",
                subtitle: "AIがより精度の高い提案をするために使います\n後から設定で変更できます"
            )

            VStack(spacing: AppTheme.Spacing.md) {
                // 身長
                MeasurementRow(
                    icon: "ruler",
                    label: "身長",
                    unit: "cm",
                    value: $height,
                    range: 140...220,
                    step: 1
                )

                Divider().padding(.horizontal, AppTheme.Spacing.lg)

                // 体重
                MeasurementRow(
                    icon: "scalemass",
                    label: "体重",
                    unit: "kg",
                    value: $weight,
                    range: 30...200,
                    step: 0.5
                )

                // BMI表示
                if bmi > 0 {
                    HStack {
                        Text("BMI")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        Text(String(format: "%.1f", bmi))
                            .font(AppTheme.Typography.monospaced)
                            .foregroundStyle(bmiLabel.color)
                        Text("(\(bmiLabel.text))")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(bmiLabel.color)
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.xs)
                }
            }
            .padding(.vertical, AppTheme.Spacing.md)
            .surfaceCard()
            .padding(.horizontal, AppTheme.Spacing.lg)

            Text("入力したデータはこのデバイス上でのみ使用されます")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)

            Spacer()
        }
    }
}

struct MeasurementRow: View {
    var icon: String
    var label: String
    var unit: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.Colors.primary)
                .frame(width: 24)

            Text(label)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            // マイナスボタン
            Button(action: {
                value = max(range.lowerBound, value - step)
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.Colors.primary.opacity(0.7))
            }

            // 数値表示
            Text(step < 1 ? String(format: "%.1f", value) : "\(Int(value))")
                .font(.system(size: 22, design: .monospaced).weight(.semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .frame(width: 64, alignment: .center)

            Text(unit)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .frame(width: 20, alignment: .leading)

            // プラスボタン
            Button(action: {
                value = min(range.upperBound, value + step)
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.Colors.primary)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}

// MARK: - Step 4: Workout Days

struct WorkoutDaysStepView: View {
    @Binding var workoutDays: Int

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            OnboardingStepHeader(
                title: "週何日運動できますか？",
                subtitle: "AIが休息日を含めた最適なスケジュールを組みます"
            )

            VStack(spacing: AppTheme.Spacing.xl) {
                // 日数表示
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("\(workoutDays)")
                        .font(.system(size: 80, design: .monospaced).weight(.bold))
                        .foregroundStyle(AppTheme.Colors.gradientPrimary)

                    Text("日 / 週")
                        .font(AppTheme.Typography.displaySmall)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                // スライダー
                VStack(spacing: AppTheme.Spacing.sm) {
                    Slider(value: Binding(
                        get: { Double(workoutDays) },
                        set: { workoutDays = Int($0) }
                    ), in: 1...7, step: 1)
                    .tint(AppTheme.Colors.primary)

                    HStack {
                        Text("1日")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        Spacer()
                        Text("7日")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)

                // 推奨コメント
                Text(workoutDaysAdvice)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }

            Spacer()
        }
    }

    var workoutDaysAdvice: String {
        switch workoutDays {
        case 1...2: return "週1〜2日は初心者に最適。無理なく習慣化しましょう。"
        case 3...4: return "週3〜4日は筋肥大・体力向上に理想的なバランスです。"
        case 5...6: return "週5〜6日は上級者向け。十分な睡眠と栄養が重要です。"
        case 7:     return "毎日のトレーニングには、軽度のアクティブリカバリーを含めます。"
        default:    return ""
        }
    }
}

// MARK: - Step 5: Equipment & HealthKit

struct EquipmentStepView: View {
    @Binding var selectedEquipment: Set<Equipment>
    var onHealthKitRequest: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                OnboardingStepHeader(
                    title: "利用できる器具を選んでください",
                    subtitle: "複数選択可能。後からSettingsで変更できます"
                )

                // 器具選択
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.sm) {
                    ForEach(Equipment.allCases, id: \.rawValue) { equipment in
                        EquipmentCard(
                            equipment: equipment,
                            isSelected: selectedEquipment.contains(equipment),
                            onTap: {
                                if selectedEquipment.contains(equipment) {
                                    selectedEquipment.remove(equipment)
                                } else {
                                    selectedEquipment.insert(equipment)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)

                // HealthKit連携
                HealthKitPermissionCard(onRequest: onHealthKitRequest)
                    .padding(.horizontal, AppTheme.Spacing.lg)
            }
            .padding(.bottom, 100)
        }
    }
}

struct EquipmentCard: View {
    var equipment: Equipment
    var isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: equipment.icon)
                    .font(.system(size: 26))
                    .foregroundStyle(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)

                Text(equipment.displayName)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(equipment.description)
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            .padding(.horizontal, AppTheme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(isSelected ? AppTheme.Colors.primary.opacity(0.1) : AppTheme.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .stroke(isSelected ? AppTheme.Colors.primary : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .animation(AppTheme.Animation.standard, value: isSelected)
    }
}

struct HealthKitPermissionCard: View {
    var onRequest: () -> Void
    @State private var requested = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(AppTheme.Colors.danger)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple HealthKit連携")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text("AIがより正確な提案をするために使用します")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                Spacer()
            }

            // 取得するデータの明示
            VStack(spacing: 6) {
                ForEach([
                    ("waveform.path.ecg", "安静時心拍数"),
                    ("moon.zzz.fill",     "睡眠時間・睡眠の質"),
                    ("figure.walk",       "歩数"),
                    ("flame.fill",        "アクティブカロリー"),
                ], id: \.1) { icon, label in
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .foregroundStyle(AppTheme.Colors.primary)
                            .frame(width: 18)
                        Text(label)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        Spacer()
                    }
                }
            }
            .padding(.vertical, AppTheme.Spacing.xs)

            Button(action: {
                requested = true
                onRequest()
            }) {
                HStack {
                    Image(systemName: requested ? "checkmark.circle.fill" : "link")
                    Text(requested ? "連携リクエスト済み" : "HealthKitと連携する")
                }
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                        .fill(requested ? AppTheme.Colors.success : AppTheme.Colors.primary)
                )
            }
            .disabled(requested)

            Text("取得したデータはすべてこの端末内でのみ処理され、\n外部サーバーには一切送信されません。\nスキップしても後から設定できます。")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.md)
        .surfaceCard()
    }
}

// MARK: - Navigation Buttons

struct OnboardingNavigationButtons: View {
    var currentStep: Int
    var totalSteps: Int
    var canProceed: Bool
    var onBack: () -> Void
    var onNext: () -> Void

    var isLastStep: Bool { currentStep == totalSteps - 1 }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            if currentStep > 0 {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .frame(width: 52, height: 52)
                        .background(
                            Circle().fill(AppTheme.Colors.surface)
                        )
                }
            }

            Button(action: onNext) {
                HStack {
                    Text(isLastStep ? "はじめる" : "次へ")
                        .font(AppTheme.Typography.headline)
                    Image(systemName: isLastStep ? "bolt.fill" : "chevron.right")
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.full)
                        .fill(canProceed ? AppTheme.Colors.gradientPrimary : LinearGradient(colors: [AppTheme.Colors.textSecondary], startPoint: .leading, endPoint: .trailing))
                )
            }
            .disabled(!canProceed)
            .animation(AppTheme.Animation.standard, value: canProceed)
        }
    }
}

// MARK: - Step Header

struct OnboardingStepHeader: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.displaySmall)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel(), onComplete: {})
        .modelContainer(for: [UserProfile.self, WorkoutSession.self, WeeklyWorkoutPlan.self], inMemory: true)
}
