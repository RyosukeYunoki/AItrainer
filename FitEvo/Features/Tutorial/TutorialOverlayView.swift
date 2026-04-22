// TutorialOverlayView.swift
// FitEvo
//
// 初回起動時のスポットライトチュートリアル。
// 画面を暗くして特定UIを光らせながら使い方を案内する。

import SwiftUI

// MARK: - TutorialStep

struct TutorialStep {
    var title: String
    var message: String
    /// スポットライトの位置・サイズ（画面サイズに対する割合 0〜1）
    var spotFraction: CGRect
    /// 吹き出しをスポットライトの上に出すか下に出すか
    var calloutAbove: Bool
}

// MARK: - TutorialOverlayView

struct TutorialOverlayView: View {
    @Binding var isShowing: Bool
    @State private var step = 0
    @State private var spotOpacity: Double = 0
    @State private var calloutOpacity: Double = 0
    @State private var borderPulse: CGFloat = 1.0

    private let steps: [TutorialStep] = [
        TutorialStep(
            title: "今日のAI提案",
            message: "AIが今日のコンディションに合ったメニューを自動で提案します。「開始」をタップするだけでトレーニングが始まります。",
            spotFraction: CGRect(x: 0.04, y: 0.13, width: 0.92, height: 0.30),
            calloutAbove: false
        ),
        TutorialStep(
            title: "今日の調子を入力",
            message: "疲れ具合を1〜5で教えてください。AIがその日のプランをリアルタイムで調整します。",
            spotFraction: CGRect(x: 0.04, y: 0.53, width: 0.92, height: 0.13),
            calloutAbove: true
        ),
        TutorialStep(
            title: "進捗を確認",
            message: "トレーニング履歴・グラフ・カレンダーを確認できます。続けるほどグラフが伸びていきます。",
            spotFraction: CGRect(x: 0.25, y: 0.895, width: 0.25, height: 0.105),
            calloutAbove: true
        ),
        TutorialStep(
            title: "体型を記録",
            message: "体重と写真を記録して自分の成長を可視化できます。定期的に撮影して変化を確認しましょう。",
            spotFraction: CGRect(x: 0.50, y: 0.895, width: 0.25, height: 0.105),
            calloutAbove: true
        ),
        TutorialStep(
            title: "設定",
            message: "AIの動作や表示をカスタマイズできます。Apple Watchとの連携状況もここで確認できます。",
            spotFraction: CGRect(x: 0.75, y: 0.895, width: 0.25, height: 0.105),
            calloutAbove: true
        )
    ]

    private var current: TutorialStep { steps[step] }
    private var isLast: Bool { step == steps.count - 1 }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let spot = resolvedSpot(in: size)

            ZStack {
                // ── ダーク オーバーレイ（スポットを切り抜き）──
                Color.black.opacity(0.72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .frame(width: spot.width, height: spot.height)
                            .position(x: spot.midX, y: spot.midY)
                            .blendMode(.destinationOut)
                    )
                    .compositingGroup()
                    .ignoresSafeArea()
                    .opacity(spotOpacity)
                    .animation(.easeInOut(duration: 0.35), value: step)

                // ── スポット 枠線（パルス）──
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.7), lineWidth: 2)
                    .frame(width: spot.width + 4, height: spot.height + 4)
                    .position(x: spot.midX, y: spot.midY)
                    .scaleEffect(borderPulse)
                    .shadow(color: .white.opacity(0.4), radius: 8)
                    .opacity(spotOpacity)
                    .animation(.easeInOut(duration: 0.35), value: step)

                // ── 吹き出し ──
                calloutView(spot: spot, screenSize: size)
                    .opacity(calloutOpacity)

                // ── スキップボタン ──
                VStack {
                    HStack {
                        Spacer()
                        Button("スキップ") { dismiss() }
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.top, AppTheme.Spacing.xl)
                    }
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { animateIn() }
    }

    // MARK: - Callout

    private var stepIcon: (name: String, color: Color) {
        switch step {
        case 0: return ("brain.fill", AppTheme.Colors.primary)
        case 1: return ("bolt.fill", AppTheme.Colors.warning)
        case 2: return ("chart.xyaxis.line", AppTheme.Colors.success)
        case 3: return ("figure.stand", AppTheme.Colors.accent)
        default: return ("gearshape.fill", AppTheme.Colors.textSecondary)
        }
    }

    @ViewBuilder
    private func calloutView(spot: CGRect, screenSize: CGSize) -> some View {
        let calloutX = screenSize.width / 2
        let icon = stepIcon
        // 吹き出しカードの概算高さ
        let cardHeight: CGFloat = 220
        let gap: CGFloat = 20
        let calloutY: CGFloat = current.calloutAbove
            ? spot.minY - gap - cardHeight / 2
            : spot.maxY + gap + cardHeight / 2

        VStack(spacing: 0) {
            // 上矢印（スポットが下にある場合）
            if !current.calloutAbove {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .offset(y: 1)
            }

            // 白カード本体
            VStack(spacing: AppTheme.Spacing.md) {

                // ステップアイコン + ステップ番号
                HStack(spacing: AppTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(icon.color.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(icon.color)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("STEP \(step + 1) / \(steps.count)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(icon.color)
                            .tracking(0.5)
                        Text(current.title)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                    }
                    Spacer()
                }

                // 説明文
                Text(current.message)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // ステップドット + ボタン
                HStack {
                    HStack(spacing: 6) {
                        ForEach(0..<steps.count, id: \.self) { i in
                            Circle()
                                .fill(i == step ? icon.color : Color(hex: "D1D5DB"))
                                .frame(width: 7, height: 7)
                        }
                    }
                    Spacer()
                    Button(action: advance) {
                        Text(isLast ? "始める" : "次へ")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 9)
                            .background(Capsule().fill(icon.color))
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 6)
            )

            // 下矢印（スポットが上にある場合）
            if current.calloutAbove {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .offset(y: -1)
            }
        }
        .frame(width: 300)
        .position(
            x: min(max(calloutX, 160), screenSize.width - 160),
            y: min(max(calloutY, cardHeight / 2 + 20), screenSize.height - cardHeight / 2 - 20)
        )
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    // MARK: - Helpers

    private func resolvedSpot(in size: CGSize) -> CGRect {
        let f = current.spotFraction
        return CGRect(
            x: f.minX * size.width,
            y: f.minY * size.height,
            width: f.width * size.width,
            height: f.height * size.height
        )
    }

    private func animateIn() {
        withAnimation(.easeOut(duration: 0.4)) { spotOpacity = 1 }
        withAnimation(.easeOut(duration: 0.35).delay(0.2)) { calloutOpacity = 1 }
        startPulse()
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            borderPulse = 1.04
        }
    }

    private func advance() {
        if isLast {
            dismiss()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { calloutOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                step += 1
                withAnimation(.easeOut(duration: 0.3)) { calloutOpacity = 1 }
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            spotOpacity    = 0
            calloutOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isShowing = false
        }
    }
}
