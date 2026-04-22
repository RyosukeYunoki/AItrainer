// AIReadyView.swift
// FitEvo
//
// オンボーディング直後に表示するAI進化訴求画面。
// 「使えば使うほど最適化される」というコアバリューを伝える。

import SwiftUI

struct AIReadyView: View {
    var onStart: () -> Void

    // アニメーション状態
    @State private var bgScale: CGFloat = 0.6
    @State private var bgOpacity: Double = 0
    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var cardsOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.9
    @State private var orbitAngle: Double = 0

    private let points: [(icon: String, color: Color, title: String, body: String)] = [
        ("waveform.path.ecg", AppTheme.Colors.success,
         "あなたのデータで学習",
         "体調・疲労・運動履歴を毎回分析"),
        ("arrow.up.right.circle.fill", AppTheme.Colors.warning,
         "提案の精度が上がり続ける",
         "続けるほどあなたの身体に合ってくる"),
        ("person.fill.checkmark", AppTheme.Colors.accent,
         "専属トレーナーに進化",
         "数週間でパーソナライズ度が大幅向上")
    ]

    var body: some View {
        ZStack {
            // ── 背景グラデーション ──
            LinearGradient(
                colors: [Color(hex: "0F172A"), Color(hex: "1E3A5F"), Color(hex: "1D4ED8")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .scaleEffect(bgScale)
            .opacity(bgOpacity)

            // ── 背景 パーティクル的なリング ──
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.white.opacity(0.04 + Double(i) * 0.02), lineWidth: 1)
                        .frame(width: CGFloat(200 + i * 80), height: CGFloat(200 + i * 80))
                        .rotationEffect(.degrees(orbitAngle + Double(i) * 30))
                }
            }
            .animation(
                .linear(duration: 12).repeatForever(autoreverses: false),
                value: orbitAngle
            )

            VStack(spacing: 0) {
                Spacer()

                // ── マスコット（メインアイコン）──
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseScale)

                    FitEvoMascot(size: 120, showAnimation: true)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                Spacer().frame(height: 32)

                // ── タイトル ──
                VStack(spacing: 10) {
                    Text("AIトレーナーが")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.6))
                        .textCase(.uppercase)

                    Text("あなたに合わせて\n進化し始めます")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(titleOpacity)
                .offset(y: titleOffset)

                Spacer().frame(height: 36)

                // ── 3つのポイント ──
                VStack(spacing: 12) {
                    ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(point.color.opacity(0.18))
                                    .frame(width: 44, height: 44)
                                Image(systemName: point.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(point.color)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(point.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text(point.body)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.6))
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white.opacity(0.07))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 24)
                .opacity(cardsOpacity)

                Spacer().frame(height: 40)

                // ── 開始ボタン ──
                Button(action: onStart) {
                    HStack(spacing: 10) {
                        Text("トレーニングを始める")
                            .font(.system(size: 17, weight: .bold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                    }
                    .foregroundStyle(Color(hex: "1D4ED8"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                            .shadow(color: .white.opacity(0.25), radius: 12, x: 0, y: 4)
                    )
                }
                .padding(.horizontal, 24)
                .scaleEffect(buttonScale)
                .opacity(buttonOpacity)

                Spacer().frame(height: 16)

                Text("ワークアウトを重ねるごとに賢くなります")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
                    .opacity(buttonOpacity)

                Spacer()
            }
        }
        .onAppear { startAnimations() }
    }

    // MARK: - Animations

    private func startAnimations() {
        // 背景
        withAnimation(.easeOut(duration: 0.5)) {
            bgScale = 1.0
            bgOpacity = 1.0
        }
        // アイコン バウンスイン
        withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(0.15)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        // アイコン パルス（無限）
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.7)) {
            pulseScale = 1.12
        }
        // リング回転（無限）
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false).delay(0.3)) {
            orbitAngle = 360
        }
        // タイトル
        withAnimation(.easeOut(duration: 0.5).delay(0.35)) {
            titleOpacity = 1.0
            titleOffset = 0
        }
        // カード
        withAnimation(.easeOut(duration: 0.5).delay(0.55)) {
            cardsOpacity = 1.0
        }
        // ボタン
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.8)) {
            buttonOpacity = 1.0
            buttonScale = 1.0
        }
    }
}

#Preview {
    AIReadyView(onStart: {})
}
