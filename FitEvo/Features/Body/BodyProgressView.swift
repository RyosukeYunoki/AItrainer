// BodyProgressView.swift
// FitEvo
//
// 体型記録・推移画面。体重・写真をタイムライン形式で管理する。

import SwiftUI
import SwiftData
import PhotosUI
import Charts

// MARK: - BodyProgressView

struct BodyProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyRecord.date, order: .reverse) private var records: [BodyRecord]

    @State private var showAddSheet = false
    @State private var selectedRecord: BodyRecord?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {

                        // 体重推移グラフ
                        let weightRecords = records.filter { $0.weight != nil }.sorted { $0.date < $1.date }
                        if weightRecords.count >= 2 {
                            WeightTrendCard(records: weightRecords)
                        }

                        // サマリー
                        if let latest = records.first, let earliest = records.last {
                            BodySummaryCard(latest: latest, earliest: earliest)
                        }

                        // 記録リスト
                        if !records.isEmpty {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                Text("記録一覧")
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)

                                ForEach(records) { record in
                                    BodyRecordRow(record: record) {
                                        selectedRecord = record
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, 100)
                }

                // 追加ボタン（FAB）
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showAddSheet = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 58, height: 58)
                                .background(
                                    Circle().fill(AppTheme.Colors.gradientPrimary)
                                )
                                .shadow(color: AppTheme.Colors.primary.opacity(0.35), radius: 12, x: 0, y: 5)
                        }
                        .padding(.trailing, AppTheme.Spacing.lg)
                        .padding(.bottom, AppTheme.Spacing.xl)
                    }
                }
            }
            .navigationTitle("体型の記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
            .sheet(isPresented: $showAddSheet) {
                AddBodyRecordSheet { record in
                    modelContext.insert(record)
                    try? modelContext.save()
                }
            }
            .sheet(item: $selectedRecord) { record in
                BodyRecordDetailSheet(record: record) {
                    modelContext.delete(record)
                    try? modelContext.save()
                    selectedRecord = nil
                }
            }
        }
    }
}

// MARK: - Weight Trend Card

struct WeightTrendCard: View {
    var records: [BodyRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundStyle(AppTheme.Colors.primary)
                Text("体重の推移")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
            }

            Chart {
                ForEach(records) { record in
                    if let w = record.weight {
                        LineMark(
                            x: .value("日付", record.date),
                            y: .value("体重", w)
                        )
                        .foregroundStyle(AppTheme.Colors.gradientPrimary)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("日付", record.date),
                            y: .value("体重", w)
                        )
                        .foregroundStyle(AppTheme.Colors.primary)
                        .symbolSize(40)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
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
                        if let kg = value.as(Double.self) {
                            Text(String(format: "%.1fkg", kg))
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                }
            }
            .frame(height: 180)
            .chartLegend(.hidden)
        }
        .padding(AppTheme.Spacing.md)
        .surfaceCard()
    }
}

// MARK: - Summary Card

struct BodySummaryCard: View {
    var latest: BodyRecord
    var earliest: BodyRecord

    var weightDiff: Double? {
        guard let lw = latest.weight, let ew = earliest.weight else { return nil }
        return lw - ew
    }

    var body: some View {
        HStack(spacing: 0) {
            BodyStatCell(
                icon: "calendar",
                label: "記録開始",
                value: dateString(earliest.date)
            )
            Divider().frame(height: 40)
            BodyStatCell(
                icon: "photo.stack",
                label: "記録数",
                value: "\(max(1, 0))件"  // will be passed from outside ideally
            )
            if let diff = weightDiff {
                Divider().frame(height: 40)
                BodyStatCell(
                    icon: diff <= 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill",
                    label: "体重変化",
                    value: String(format: "%+.1fkg", diff),
                    valueColor: diff <= 0 ? AppTheme.Colors.success : AppTheme.Colors.warning
                )
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .surfaceCard()
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M月d日"
        return f.string(from: date)
    }
}

struct BodyStatCell: View {
    var icon: String
    var label: String
    var value: String
    var valueColor: Color = AppTheme.Colors.textPrimary

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(AppTheme.Colors.primary)
            Text(value)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(valueColor)
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

// MARK: - Record Row

struct BodyRecordRow: View {
    var record: BodyRecord
    var onTap: () -> Void

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月d日 (E)"
        return f
    }()

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.md) {
                // サムネイル
                if let data = record.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sm))
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                        .fill(AppTheme.Colors.surface2)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(dateFormatter.string(from: record.date))
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    if let w = record.weight {
                        Text(String(format: "%.1f kg", w))
                            .font(AppTheme.Typography.monospaced)
                            .foregroundStyle(AppTheme.Colors.primary)
                    }

                    if !record.note.isEmpty {
                        Text(record.note)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(AppTheme.Colors.surface)
            )
        }
    }
}

// MARK: - Add Record Sheet

struct AddBodyRecordSheet: View {
    var onSave: (BodyRecord) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate = Date()
    @State private var weightText = ""
    @State private var note = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoImage: UIImage?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {

                        // 写真選択
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack {
                                if let img = photoImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 220)
                                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                                } else {
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                        .fill(AppTheme.Colors.surface)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 220)
                                        .overlay(
                                            VStack(spacing: AppTheme.Spacing.sm) {
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 36))
                                                    .foregroundStyle(AppTheme.Colors.primary)
                                                Text("写真を追加")
                                                    .font(AppTheme.Typography.body)
                                                    .foregroundStyle(AppTheme.Colors.primary)
                                                Text("タップして選択（任意）")
                                                    .font(AppTheme.Typography.caption)
                                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                                            }
                                        )
                                }
                            }
                        }
                        .onChange(of: selectedPhoto) { _, item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    photoImage = img
                                }
                            }
                        }

                        // 入力フォーム
                        VStack(spacing: AppTheme.Spacing.md) {
                            // 日付
                            HStack {
                                Label("日付", systemImage: "calendar")
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                Spacer()
                                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .environment(\.locale, Locale(identifier: "ja_JP"))
                            }
                            .padding(AppTheme.Spacing.md)
                            .background(RoundedRectangle(cornerRadius: AppTheme.Radius.md).fill(AppTheme.Colors.surface))

                            // 体重
                            HStack {
                                Label("体重", systemImage: "scalemass")
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                Spacer()
                                TextField("例: 65.0", text: $weightText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(AppTheme.Typography.monospaced)
                                    .foregroundStyle(AppTheme.Colors.primary)
                                    .frame(width: 80)
                                Text("kg")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }
                            .padding(AppTheme.Spacing.md)
                            .background(RoundedRectangle(cornerRadius: AppTheme.Radius.md).fill(AppTheme.Colors.surface))

                            // メモ
                            VStack(alignment: .leading, spacing: 8) {
                                Label("メモ（任意）", systemImage: "note.text")
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                TextField("今日の気づきや変化など", text: $note, axis: .vertical)
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                    .lineLimit(3...5)
                            }
                            .padding(AppTheme.Spacing.md)
                            .background(RoundedRectangle(cornerRadius: AppTheme.Radius.md).fill(AppTheme.Colors.surface))
                        }

                        // 保存ボタン
                        Button(action: save) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("記録を保存")
                                        .font(AppTheme.Typography.headline)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                    .fill(AppTheme.Colors.gradientPrimary)
                            )
                        }
                        .disabled(isSaving)
                    }
                    .padding(AppTheme.Spacing.md)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("記録を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        let weight = Double(weightText.replacingOccurrences(of: ",", with: "."))
        var jpegData: Data?
        if let img = photoImage {
            jpegData = img.jpegData(compressionQuality: 0.7)
        }
        let record = BodyRecord(date: selectedDate, weight: weight, photoData: jpegData, note: note)
        onSave(record)
        dismiss()
    }
}

// MARK: - Detail Sheet

struct BodyRecordDetailSheet: View {
    var record: BodyRecord
    var onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月d日 (EEEE)"
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {

                        // 写真
                        if let data = record.photoData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                        }

                        // 情報
                        VStack(spacing: AppTheme.Spacing.sm) {
                            InfoRow(label: "記録日", value: dateFormatter.string(from: record.date))

                            if let w = record.weight {
                                InfoRow(label: "体重", value: String(format: "%.1f kg", w))
                            }

                            if !record.note.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("メモ")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.Colors.textSecondary)
                                    Text(record.note)
                                        .font(AppTheme.Typography.body)
                                        .foregroundStyle(AppTheme.Colors.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(AppTheme.Spacing.md)
                                .surfaceCard()
                            }
                        }

                        Button(role: .destructive, action: { showDeleteConfirm = true }) {
                            Label("この記録を削除", systemImage: "trash")
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.Colors.danger)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                        .fill(AppTheme.Colors.danger.opacity(0.08))
                                )
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("記録の詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(AppTheme.Colors.primary)
                }
            }
            .alert("記録を削除しますか？", isPresented: $showDeleteConfirm) {
                Button("削除", role: .destructive) { onDelete() }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この操作は取り消せません。")
            }
        }
    }
}

struct InfoRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .padding(AppTheme.Spacing.md)
        .surfaceCard()
    }
}

// MARK: - Empty State

struct BodyEmptyState: View {
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            VStack(spacing: AppTheme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.primary.opacity(0.1))
                        .frame(width: 120, height: 120)
                    Image(systemName: "figure.stand")
                        .font(.system(size: 52))
                        .foregroundStyle(AppTheme.Colors.primary)
                }

                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("体型記録を始めましょう")
                        .font(AppTheme.Typography.displaySmall)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text("体重と写真を記録して\n自分の成長を可視化できます")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Button(action: onAdd) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("最初の記録を追加")
                            .font(AppTheme.Typography.headline)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(
                        Capsule().fill(AppTheme.Colors.gradientPrimary)
                    )
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    BodyProgressView()
        .modelContainer(for: [UserProfile.self, WorkoutSession.self, WeeklyWorkoutPlan.self, BodyRecord.self], inMemory: true)
}
