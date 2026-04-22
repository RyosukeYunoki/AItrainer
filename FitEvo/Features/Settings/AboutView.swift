// AboutView.swift
// FitEvo
//
// アプリについて画面。
// ユーザー向けの説明・技術解説（研究アピール用）・利用規約・プライバシーポリシーを含む。

import SwiftUI

// MARK: - AboutView

struct AboutView: View {
    @State private var selectedTab: AboutTab = .overview

    enum AboutTab: String, CaseIterable {
        case overview  = "概要"
        case legal     = "利用規約等"
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // タブセレクター
                Picker("", selection: $selectedTab) {
                    ForEach(AboutTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(AppTheme.Spacing.md)

                // コンテンツ
                ScrollView {
                    switch selectedTab {
                    case .overview: AppOverviewSection()
                    case .legal:    LegalSection()
                    }
                }
            }
        }
        .navigationTitle("このアプリについて")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
    }
}

// MARK: - 概要タブ

struct AppOverviewSection: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {

            // ロゴ＋キャッチ
            VStack(spacing: AppTheme.Spacing.md) {
                FitEvoMascot(size: 90, showAnimation: true)

                VStack(spacing: 6) {
                    Text("FitEvo")
                        .font(AppTheme.Typography.displayMedium)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text("バージョン 1.0.0")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            .padding(.top, AppTheme.Spacing.md)

            // アプリの説明
            AboutCard(icon: "cpu", color: AppTheme.Colors.primary, title: "FitEvoとは") {
                Text("FitEvoは、AIがあなたの体調データを読み取り、毎週のトレーニングメニューを自動的に最適化するフィットネスアプリです。\n\nトレーニングを続けるほどAIがあなたの身体の傾向を学習し、より的確な提案ができるようになります。")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            // 機能一覧
            AboutCard(icon: "star.fill", color: AppTheme.Colors.warning, title: "主な機能") {
                VStack(alignment: .leading, spacing: 12) {
                    FeatureItem(icon: "heart.fill", text: "ヘルスケアアプリの心拍・睡眠・歩数データを自動で読み取り")
                    FeatureItem(icon: "bolt.fill", text: "AIが毎日のコンディションに合わせたメニューを提案")
                    FeatureItem(icon: "chart.xyaxis.line", text: "トレーニング履歴と進捗をグラフで確認")
                    FeatureItem(icon: "lock.shield.fill", text: "すべてのデータはこの端末内だけで処理。外部サーバーへの送信なし")
                    FeatureItem(icon: "arrow.triangle.2.circlepath", text: "3種類のAIモードを切り替えて使い比べ可能")
                }
            }

            // データの安全性
            AboutCard(icon: "lock.shield.fill", color: AppTheme.Colors.success, title: "プライバシーへの取り組み") {
                VStack(alignment: .leading, spacing: 12) {
                    PrivacyItem(text: "健康データはすべてこの端末内だけで処理されます")
                    PrivacyItem(text: "外部のサーバーやクラウドにデータを送ることは一切ありません")
                    PrivacyItem(text: "ヘルスケアの許可はいつでも「設定」アプリから変更できます")
                    PrivacyItem(text: "アプリを削除すればすべてのデータが端末から消去されます")
                }
            }

        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.bottom, 40)
    }
}

// MARK: - AIの仕組みタブ（技術解説・研究アピール用）

struct TechnicalSection: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {

            // 注意書き
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(AppTheme.Colors.warning)
                Text("このセクションはAIの技術的な仕組みに興味のある方向けの詳しい解説です")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                    .fill(AppTheme.Colors.warning.opacity(0.08))
            )
            .padding(.top, AppTheme.Spacing.sm)

            // 状態空間
            TechCard(title: "AIが観察するデータ（状態空間）", icon: "eye.fill") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AIは以下の10種類のデータをもとに判断を行います。")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    TechDataRow(label: "安静時心拍数", detail: "疲労・ストレスの指標")
                    TechDataRow(label: "前日の睡眠時間", detail: "回復の質を示す最重要指標")
                    TechDataRow(label: "前日の歩数", detail: "日常活動量の代理指標")
                    TechDataRow(label: "体重", detail: "目標進捗の追跡に使用")
                    TechDataRow(label: "消費カロリー", detail: "運動強度の客観指標")
                    TechDataRow(label: "主観的疲労度", detail: "あなた自身が入力する1〜5の評価")
                    TechDataRow(label: "前回からの日数", detail: "過剰休息の検出に使用")
                    TechDataRow(label: "週次継続率", detail: "習慣形成の指標（0〜100%）")
                    TechDataRow(label: "連続トレーニング日数", detail: "連続記録の追跡")
                    TechDataRow(label: "目標達成進捗率", detail: "長期目標に対する現在地")
                }
            }

            // 報酬関数
            TechCard(title: "AIの評価基準（報酬関数）", icon: "function") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("AIはトレーニングの良し悪しを以下の式で数値化します。")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)

                    // 数式（コードブロック風）
                    Text("R = α×目標進捗 + β×継続率 − γ×過学習リスク + δ×身体適応")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(AppTheme.Colors.primary)
                        .padding(AppTheme.Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                                .fill(AppTheme.Colors.surface2)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        RewardTermRow(symbol: "α（目標進捗）", value: "0.4", description: "目標に近づいているかを評価")
                        RewardTermRow(symbol: "β（継続率）", value: "0.3", description: "続けられているかを評価")
                        RewardTermRow(symbol: "γ（過学習リスク）", value: "0.2", description: "疲れているのに無理をしていないか")
                        RewardTermRow(symbol: "δ（身体適応）", value: "0.1", description: "適切な回復サイクルが取れているか")
                    }

                    Text("設定画面の「AIの優先事項」でこれらの重みを変更できます。")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }

            // 各アルゴリズムの技術解説
            ForEach(AlgorithmType.allCases, id: \.rawValue) { type in
                TechCard(title: "\(type.displayName)の仕組み", icon: type.icon) {
                    Text(type.technicalDescription)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.bottom, 40)
    }
}

// MARK: - 利用規約等タブ

struct LegalSection: View {
    @State private var selectedLegal: LegalDocument? = nil

    enum LegalDocument: String, CaseIterable {
        case terms   = "利用規約"
        case privacy = "プライバシーポリシー"
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {

            ForEach(LegalDocument.allCases, id: \.rawValue) { doc in
                Button(action: { selectedLegal = doc }) {
                    HStack {
                        Image(systemName: doc == .terms ? "doc.text.fill" : "lock.shield.fill")
                            .foregroundStyle(AppTheme.Colors.primary)
                        Text(doc.rawValue)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    .padding(AppTheme.Spacing.md)
                    .surfaceCard()
                }
            }

            // 免責事項サマリー
            AboutCard(icon: "exclamationmark.triangle.fill", color: AppTheme.Colors.warning, title: "重要なお知らせ") {
                VStack(alignment: .leading, spacing: 8) {
                    DisclaimerItem(text: "本アプリはフィットネスの習慣化を支援するものであり、医療的なアドバイスや診断を行うものではありません")
                    DisclaimerItem(text: "持病をお持ちの方や体調に不安のある方は、運動前に医師にご相談ください")
                    DisclaimerItem(text: "AIの提案に無理を感じた場合は、ご自身の判断を優先してください")
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.sm)
        .padding(.bottom, 40)
        .sheet(item: $selectedLegal) { doc in
            LegalDocumentView(document: doc)
        }
    }
}

// MARK: - 法的文書シート

struct LegalDocumentView: View {
    var document: LegalSection.LegalDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        if document == .terms {
                            TermsOfServiceContent()
                        } else {
                            PrivacyPolicyContent()
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                }
            }
            .navigationTitle(document.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
            .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(AppTheme.Colors.primary)
                }
            }
        }
    }
}

// MARK: - 利用規約本文

struct TermsOfServiceContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            LegalHeader(title: "FitEvo 利用規約", date: "最終更新日：2026年4月17日")

            LegalSection2(title: "第1条（本規約の目的）",
                "本利用規約（以下「本規約」）は、FitEvo（以下「本アプリ」）を使用するすべての方（以下「ユーザー」）が本アプリを利用するにあたっての条件を定めるものです。本アプリをご利用いただくことで、本規約に同意いただいたものとみなします。")

            LegalSection2(title: "第2条（利用資格）",
                "本アプリは、13歳以上の方を対象としています。13歳未満の方は保護者の同意を得た上でご利用ください。")

            LegalSection2(title: "第3条（本アプリの目的）",
                "本アプリは、人工知能（AI）技術を活用したフィットネス習慣の継続をサポートすることを目的としています。本アプリが提供するトレーニングの提案はあくまでも参考情報であり、医療的なアドバイス・診断・治療を行うものではありません。")

            LegalSection2(title: "第4条（禁止事項）",
                "ユーザーは以下の行為を行ってはなりません。\n  ・本アプリを違法な目的で使用すること\n  ・本アプリを逆コンパイル・リバースエンジニアリングすること\n  ・本アプリの著作権・商標権等の知的財産権を侵害する行為\n  ・本アプリの正常な動作を妨害する行為")

            LegalSection2(title: "第5条（免責事項）",
                "開発者は以下の事項について一切の責任を負いません。\n  ・本アプリの利用によって生じたケガ・体調不良・その他の損害\n  ・AIが提案するトレーニング内容の正確性・有効性\n  ・本アプリの一時停止・終了・不具合によって生じた損害\n  ・その他本アプリの利用に関連して生じたあらゆる損害\n\n持病・慢性疾患をお持ちの方や、身体的不調を感じている方は、運動を開始する前に必ず医師にご相談ください。")

            LegalSection2(title: "第6条（知的財産権）",
                "本アプリおよび本アプリに含まれるすべてのコンテンツ（デザイン・プログラム・テキスト等）に関する著作権・その他の知的財産権は開発者に帰属します。")

            LegalSection2(title: "第7条（規約の変更）",
                "開発者は必要に応じて本規約を変更することがあります。重要な変更がある場合には、アプリ内でお知らせします。変更後に本アプリをご利用いただいた場合、変更後の規約に同意いただいたものとみなします。")

            LegalSection2(title: "第8条（準拠法・管轄）",
                "本規約は日本法に準拠します。本規約に関する紛争については、開発者の所在地を管轄する地方裁判所を第一審の専属的合意管轄裁判所とします。")
        }
    }
}

// MARK: - プライバシーポリシー本文

struct PrivacyPolicyContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            LegalHeader(title: "FitEvo プライバシーポリシー", date: "最終更新日：2026年4月17日")

            Text("本プライバシーポリシーは、FitEvo（以下「本アプリ」）がユーザーの個人情報・プライバシー情報をどのように取り扱うかを説明するものです。")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            LegalSection2(title: "1. 収集する情報",
                "本アプリはAppleのHealthKitフレームワークを通じて以下の健康データにアクセスします（ユーザーが許可した場合に限ります）。\n  ・安静時心拍数\n  ・睡眠時間・睡眠の質\n  ・歩数\n  ・体重\n  ・アクティブカロリー消費量\n\nまた、アプリ内でユーザーが入力する以下の情報を端末内に保存します。\n  ・主観的疲労度（1〜5の評価）\n  ・フィットネス目標・レベルの設定\n  ・トレーニング履歴\n  ・AIの学習データ")

            LegalSection2(title: "2. 情報の利用目的",
                "収集した情報は以下の目的にのみ使用します。\n  ・AIがトレーニングメニューを生成・最適化するため\n  ・進捗グラフ・統計情報を表示するため\n  ・AIの学習・改善のため（端末内処理のみ）")

            LegalSection2(title: "3. 情報の保存・管理",
                "本アプリが収集するすべての情報は、ユーザーの端末内にのみ保存されます。\n\n・外部サーバー・クラウドへのデータ送信は一切行いません\n・第三者への情報提供・販売は一切行いません\n・アプリを削除することで、端末に保存されたすべてのデータが消去されます\n・HealthKitのデータは端末のセキュアな領域で管理されるAppleの仕様に従います")

            LegalSection2(title: "4. HealthKitへのアクセス",
                "本アプリはAppleのHealthKitフレームワークを使用して健康データにアクセスします。\n\n・アクセスの許可・拒否はオンボーディング時またはiOSの設定アプリから変更できます\n・HealthKitへのアクセスを拒否しても、本アプリはサンプルデータで動作します\n・取得したHealthKitデータはAppleのHealthKit利用規約に従って取り扱います")

            LegalSection2(title: "5. セキュリティ",
                "本アプリのデータは端末内のSwiftData（iOS標準データベース）に保存されます。端末のロック・生体認証によって保護されます。\n\nただし、端末の紛失・盗難・不正アクセス等による情報漏洩については、開発者は責任を負いかねます。端末のセキュリティ設定を適切に行うことをお勧めします。")

            LegalSection2(title: "6. 未成年者のプライバシー",
                "本アプリは13歳未満の方の個人情報を意図的に収集しません。13歳未満の方がご利用の場合は、保護者の管理のもとでご使用ください。")

            LegalSection2(title: "7. ポリシーの変更",
                "本プライバシーポリシーは必要に応じて改訂されることがあります。重要な変更がある場合にはアプリ内でお知らせします。")

            LegalSection2(title: "8. お問い合わせ",
                "プライバシーに関するご質問・ご要望は、App Store内の開発者情報よりご連絡ください。")
        }
    }
}

// MARK: - 共通UIコンポーネント（About画面用）

struct AboutCard<Content: View>: View {
    var icon: String
    var color: Color
    var title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .surfaceCard()
    }
}

struct TechCard<Content: View>: View {
    var title: String
    var icon: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.Colors.accent)
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            content()
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .stroke(AppTheme.Colors.accent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct FeatureItem: View {
    var icon: String
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.Colors.primary)
                .frame(width: 20)
                .padding(.top, 1)
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
}

struct PrivacyItem: View {
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(AppTheme.Colors.success)
                .frame(width: 20)
                .padding(.top, 1)
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
}

struct DisclaimerItem: View {
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(AppTheme.Colors.warning)
                .frame(width: 20)
                .padding(.top, 1)
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
}

struct TechDataRow: View {
    var label: String
    var detail: String

    var body: some View {
        HStack(alignment: .top) {
            Text("・\(label)")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .frame(width: 140, alignment: .leading)
            Text(detail)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
}

struct RewardTermRow: View {
    var symbol: String
    var value: String
    var description: String

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Text(symbol)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.accent)
                .frame(width: 110, alignment: .leading)
            Text("初期値 \(value)：\(description)")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
}

struct LegalHeader: View {
    var title: String
    var date: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTheme.Typography.displaySmall)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(date)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
}

struct LegalSection2: View {
    var title: String
    var text: String

    init(title: String, _ text: String) {
        self.title = title
        self.text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
}

// MARK: - LegalDocument Identifiable

extension LegalSection.LegalDocument: Identifiable {
    var id: String { rawValue }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
