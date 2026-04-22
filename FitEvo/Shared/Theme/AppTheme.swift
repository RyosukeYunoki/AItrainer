// AppTheme.swift
// FitEvo
//
// デザインシステムの中枢。カラー・フォント・スペーシングをすべてここで管理する。
// 白基調のシンプル・クリーンなデザイン。

import SwiftUI

// MARK: - Color Extension (Hex Support)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - AppTheme

enum AppTheme {

    // MARK: - Colors

    enum Colors {
        /// 薄いグレー白 — アプリの基底背景色
        static let background    = Color(hex: "F4F6FA")
        /// 純白 — カード背景
        static let surface        = Color.white
        /// 薄いブルーグレー — 入力フィールド・セカンダリ背景
        static let surface2       = Color(hex: "EDF0F7")
        /// 鮮やかな青 — プライマリアクション
        static let primary        = Color(hex: "2563EB")
        /// 紫 — AIアクセント
        static let accent         = Color(hex: "7C3AED")
        /// 緑 — 達成・成功
        static let success        = Color(hex: "10B981")
        /// 琥珀 — 注意・警告
        static let warning        = Color(hex: "F59E0B")
        /// 赤 — エラー・危険
        static let danger         = Color(hex: "EF4444")
        /// メインテキスト
        static let textPrimary    = Color(hex: "111827")
        /// サブテキスト
        static let textSecondary  = Color(hex: "6B7280")
        /// 薄いテキスト
        static let textTertiary   = Color(hex: "9CA3AF")
        /// 区切り線・チャートグリッド線
        static let separator      = Color(hex: "E5E7EB")

        /// グラデーション: 青→紫
        static let gradientPrimary = LinearGradient(
            colors: [primary, accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// グラデーション: 成功
        static let gradientSuccess = LinearGradient(
            colors: [Color(hex: "10B981"), Color(hex: "059669")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// グラデーション: 警告
        static let gradientWarning = LinearGradient(
            colors: [Color(hex: "F59E0B"), Color(hex: "DC2626")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Typography

    enum Typography {
        static let displayLarge   = Font.system(.largeTitle, design: .default, weight: .bold)
        static let displayMedium  = Font.system(.title, design: .default, weight: .bold)
        static let displaySmall   = Font.system(.title2, design: .default, weight: .semibold)
        static let headline        = Font.system(.headline, design: .default, weight: .semibold)
        static let body            = Font.system(.body, design: .default, weight: .regular)
        static let caption         = Font.system(.caption, design: .default, weight: .regular)
        static let monospaced      = Font.system(.body, design: .monospaced, weight: .medium)
        static let monospacedLarge = Font.system(.title, design: .monospaced, weight: .bold)
        static let monospacedSmall = Font.system(.caption, design: .monospaced, weight: .regular)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum Radius {
        static let sm:   CGFloat = 12
        static let md:   CGFloat = 16
        static let lg:   CGFloat = 24
        static let full: CGFloat = 9999
    }

    // MARK: - Animation

    enum Animation {
        static let agentDecision = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.75)
        static let standard      = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let chart         = SwiftUI.Animation.easeOut(duration: 0.7)
    }

    // MARK: - Shadow

    enum Shadow {
        static let card   = (color: Color.black.opacity(0.07), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(3))
        static let subtle = (color: Color.black.opacity(0.04), radius: CGFloat(6),  x: CGFloat(0), y: CGFloat(1))
    }
}

// MARK: - View Modifier: Surface Card

struct SurfaceCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.Radius.md

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.Colors.surface)
                    .shadow(
                        color: AppTheme.Shadow.card.color,
                        radius: AppTheme.Shadow.card.radius,
                        x: AppTheme.Shadow.card.x,
                        y: AppTheme.Shadow.card.y
                    )
            )
    }
}

extension View {
    func surfaceCard(cornerRadius: CGFloat = AppTheme.Radius.md) -> some View {
        modifier(SurfaceCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - View Modifier: Glass Card

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.Radius.md

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(AppTheme.Colors.separator, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = AppTheme.Radius.md) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}
