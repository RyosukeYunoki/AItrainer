// FitEvoMascot.swift
// FitEvo
//
// FitEvoオリジナルマスコット「フィット」。
// スポーツ感あるロボット型AIトレーナーキャラ。
// showAnimation = true でフル演出（イントロ用）。

import SwiftUI

// MARK: - FitEvoMascot

struct FitEvoMascot: View {
    var size: CGFloat = 80
    var showAnimation: Bool = false

    // ── アニメーション状態 ──
    @State private var floatOffset: CGFloat = 0
    @State private var antennaAngle: Double = -3
    @State private var tipGlow: CGFloat = 5
    @State private var isBlinking = false

    // ── サイズ定数 ──
    private var faceW: CGFloat   { size * 0.92 }
    private var faceH: CGFloat   { size * 0.80 }
    private var eyeSize: CGFloat { size * 0.175 }
    private var stemH: CGFloat   { size * 0.18 }
    private var tipD: CGFloat    { size * 0.115 }

    var body: some View {
        ZStack(alignment: .top) {

            // ── アンテナ（ヘッドセット風）──
            VStack(spacing: 0) {
                Circle()
                    .fill(Color(hex: "F59E0B"))
                    .frame(width: tipD, height: tipD)
                    .shadow(color: Color(hex: "F59E0B").opacity(0.85), radius: tipGlow)
                Capsule()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: size * 0.038, height: stemH)
            }
            .rotationEffect(.degrees(antennaAngle), anchor: .bottom)

            // ── 顔 ──
            ZStack {

                // ① ベース頭部 + ヘッドバンドをまとめてクリップ
                ZStack {
                    // 青グラデーション頭部
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "3B82F6"), Color(hex: "1A3FBF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))

                    // オレンジ ヘッドバンド（上部28%）
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [Color(hex: "F97316"), Color(hex: "EA580C")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: faceH * 0.26)
                        // ヘッドバンド下線
                        Rectangle()
                            .fill(Color.white.opacity(0.25))
                            .frame(height: faceH * 0.028)
                        Spacer()
                    }

                    // ヘッドバンド中央のスポーツライン
                    HStack(spacing: size * 0.06) {
                        Capsule()
                            .fill(Color.white.opacity(0.35))
                            .frame(width: size * 0.08, height: faceH * 0.06)
                        Capsule()
                            .fill(Color.white.opacity(0.55))
                            .frame(width: size * 0.18, height: faceH * 0.06)
                        Capsule()
                            .fill(Color.white.opacity(0.35))
                            .frame(width: size * 0.08, height: faceH * 0.06)
                    }
                    .offset(y: -faceH * 0.355)
                }
                .frame(width: faceW, height: faceH)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.20))
                .shadow(color: Color(hex: "1D4ED8").opacity(0.5),
                        radius: size * 0.13, y: size * 0.055)

                // ② 眉毛（キリッとした表情 → トレーナー感）
                HStack(spacing: size * 0.15) {
                    TrainerBrow(size: size, isLeft: true)
                    TrainerBrow(size: size, isLeft: false)
                }
                .offset(y: -faceH * 0.04)

                // ③ 目
                HStack(spacing: size * 0.15) {
                    MascotEye(size: eyeSize)
                    MascotEye(size: eyeSize)
                }
                .scaleEffect(CGSize(width: 1.0, height: isBlinking ? 0.05 : 1.0))
                .animation(.easeIn(duration: 0.07), value: isBlinking)
                .offset(y: faceH * 0.04)

                // ④ 口（自信に満ちた笑顔）
                MascotSmile(width: faceW * 0.54, height: faceH * 0.16,
                            strokeWidth: size * 0.042)
                    .offset(y: faceH * 0.24)

                // ⑤ 頬（オレンジ系）
                HStack(spacing: size * 0.40) {
                    Ellipse()
                        .fill(Color(hex: "FB923C").opacity(0.38))
                        .frame(width: size * 0.125, height: size * 0.075)
                    Ellipse()
                        .fill(Color(hex: "FB923C").opacity(0.38))
                        .frame(width: size * 0.125, height: size * 0.075)
                }
                .offset(y: faceH * 0.15)

            }
            .offset(y: stemH * 0.84)
        }
        .offset(y: floatOffset)
        .onAppear {
            if showAnimation { startAnimations() }
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            floatOffset = -8
        }
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            antennaAngle = 4
        }
        withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
            tipGlow = 13
        }
        scheduleBlink()
    }

    private func scheduleBlink() {
        let interval = Double.random(in: 2.8...5.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            isBlinking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                isBlinking = false
                scheduleBlink()
            }
        }
    }
}

// MARK: - TrainerBrow（眉毛）

private struct TrainerBrow: View {
    var size: CGFloat
    var isLeft: Bool

    var body: some View {
        Capsule()
            .fill(Color.white.opacity(0.9))
            .frame(width: size * 0.14, height: size * 0.028)
            .rotationEffect(.degrees(isLeft ? -12 : 12))
    }
}

// MARK: - MascotEye

private struct MascotEye: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)
            Circle()
                .fill(RadialGradient(
                    colors: [Color(hex: "1E40AF"), Color(hex: "1E3A8A")],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.3
                ))
                .frame(width: size * 0.58, height: size * 0.58)
            Circle()
                .fill(Color.white.opacity(0.92))
                .frame(width: size * 0.22, height: size * 0.22)
                .offset(x: size * 0.12, y: -size * 0.10)
        }
    }
}

// MARK: - MascotSmile

private struct MascotSmile: View {
    var width: CGFloat
    var height: CGFloat
    var strokeWidth: CGFloat

    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: size.width * 0.08, y: size.height * 0.18))
            path.addQuadCurve(
                to: CGPoint(x: size.width * 0.92, y: size.height * 0.18),
                control: CGPoint(x: size.width * 0.50, y: size.height * 1.0)
            )
            context.stroke(
                path,
                with: .color(Color.white.opacity(0.90)),
                style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
            )
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "0F172A").ignoresSafeArea()
        HStack(spacing: 36) {
            VStack(spacing: 8) {
                FitEvoMascot(size: 120, showAnimation: true)
                Text("イントロ").font(.caption).foregroundStyle(.white)
            }
            VStack(spacing: 8) {
                FitEvoMascot(size: 72)
                Text("チャット").font(.caption).foregroundStyle(.white)
            }
            VStack(spacing: 8) {
                FitEvoMascot(size: 42)
                Text("バナー").font(.caption).foregroundStyle(.white)
            }
        }
    }
}
