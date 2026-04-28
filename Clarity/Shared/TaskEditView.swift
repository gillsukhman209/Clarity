//
//  TaskEditView.swift
//  Clarity
//
//  Shared editor for an existing task. Lets the user change anything:
//  title, category, priority, when it starts (date + time, or flag it as
//  anytime), duration (or none), and notes. Saves through TaskStore.update.
//

import SwiftUI

struct TaskEditView: View {
    let taskID: UUID
    var onClose: () -> Void = {}

    @Environment(TaskStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var category: TaskCategory = .personal
    @State private var priority: TaskPriority = .medium
    @State private var hasTime: Bool = true
    @State private var startDate: Date = Date()
    @State private var durationMinutes: Int = 0

    @State private var loaded: Bool = false

    var body: some View {
        Group {
            if let task = store.task(with: taskID) {
                editor(for: task)
                    .onAppear { if !loaded { hydrate(from: task) } }
            } else {
                missing
            }
        }
        .frame(minWidth: 420, idealWidth: 520, minHeight: 540)
        .background(AppColors.background)
    }

    private var missing: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "tray")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
            Text("Task no longer exists")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func editor(for task: PlanTask) -> some View {
        VStack(spacing: 0) {
            topBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    titleField
                    categoryRow
                    priorityRow
                    timeRow
                    durationRow
                    notesField
                }
                .padding(AppSpacing.lg)
            }

            Divider().background(AppColors.divider)

            footer(for: task)
                .padding(AppSpacing.lg)
        }
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            Button("Cancel") { close() }
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
                .buttonStyle(.plain)
            Spacer()
            Text("Edit Task")
                .font(AppTypography.titleSmall)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Button("Save") { save() }
                .font(AppTypography.bodySemibold)
                .foregroundStyle(canSave ? AppColors.accent : AppColors.textTertiary)
                .buttonStyle(.plain)
                .disabled(!canSave)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - Fields
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Title")
            TextField("Title", text: $title, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1...3)
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .fill(AppColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        }
    }

    private var categoryRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Category")
            chipFlow(
                items: TaskCategory.allCases,
                isSelected: { $0 == category },
                label: { $0.title },
                icon:  { $0.sfSymbol },
                tint:  { $0.inkColor },
                fill:  { $0.fillColor },
                onTap: { category = $0 }
            )
        }
    }

    private var priorityRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Priority")
            HStack(spacing: 8) {
                ForEach(TaskPriority.allCases, id: \.self) { p in
                    Button { priority = p } label: {
                        Text(p.title)
                            .font(AppTypography.caption.weight(.semibold))
                            .foregroundStyle(priority == p ? p.inkColor : AppColors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(priority == p ? p.fillColor.opacity(0.6) : AppColors.surface)
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(priority == p ? p.inkColor.opacity(0.5) : AppColors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
    }

    private var timeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionLabel("When")
                Spacer()
                Toggle("Set a time", isOn: $hasTime)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                Text(hasTime ? "Has time" : "Anytime")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            if hasTime {
                DatePicker(
                    "Start",
                    selection: $startDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
            } else {
                DatePicker(
                    "Day",
                    selection: $startDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
            }
        }
    }

    private var durationRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Duration")
            HStack(spacing: 8) {
                durationChip(label: "None", isOn: durationMinutes == 0) {
                    durationMinutes = 0
                }
                ForEach([15, 30, 45, 60, 90, 120], id: \.self) { mins in
                    durationChip(label: durationLabel(mins), isOn: durationMinutes == mins) {
                        durationMinutes = mins
                    }
                }
                Spacer()
                if durationMinutes > 0 {
                    Stepper("", value: $durationMinutes, in: 5...480, step: 5)
                        .labelsHidden()
                    Text("\(durationMinutes)m")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                        .monospacedDigit()
                        .frame(minWidth: 44, alignment: .trailing)
                } else {
                    Text("Open-ended")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
        }
    }

    private func durationChip(label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(isOn ? .white : AppColors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(isOn ? AppColors.accent : AppColors.surface)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isOn ? AppColors.accent : AppColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Notes")
            TextField("Anything to remember", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2...8)
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .fill(AppColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        }
    }

    // MARK: - Footer
    @ViewBuilder
    private func footer(for task: PlanTask) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Button(role: .destructive) {
                store.delete(task.id)
                close()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Delete")
                        .font(AppTypography.bodySemibold)
                }
                .foregroundStyle(AppColors.Priority.highInk)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .stroke(AppColors.Priority.highInk.opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Spacer()

            Button { save() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Save changes")
                        .font(AppTypography.bodySemibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(canSave ? AppColors.accent : AppColors.accent.opacity(0.4))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
    }

    // MARK: - Helpers

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(AppTypography.captionSemibold)
            .tracking(0.6)
            .foregroundStyle(AppColors.textTertiary)
    }

    private func durationLabel(_ mins: Int) -> String {
        if mins < 60 { return "\(mins)m" }
        let h = mins / 60
        let m = mins % 60
        return m == 0 ? "\(h)h" : "\(h)h\(m)"
    }

    private func hydrate(from task: PlanTask) {
        title = task.title
        notes = task.notes ?? ""
        category = task.category
        priority = task.priority
        hasTime = task.hasTime
        startDate = task.startTime
        durationMinutes = task.durationMinutes
        loaded = true
    }

    private func save() {
        guard let existing = store.task(with: taskID) else {
            close(); return
        }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let cleanedNotes: String? = {
            let t = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }()

        let resolvedStart: Date = hasTime
            ? startDate
            : Calendar.current.startOfDay(for: startDate)

        var updated = existing
        updated.title = trimmed
        updated.notes = cleanedNotes
        updated.category = category
        updated.priority = priority
        updated.hasTime = hasTime
        updated.startTime = resolvedStart
        updated.durationMinutes = durationMinutes

        store.update(updated)
        close()
    }

    private func close() {
        onClose()
        dismiss()
    }

    // MARK: - Chip flow layout
    @ViewBuilder
    private func chipFlow<T: Hashable>(
        items: [T],
        isSelected: @escaping (T) -> Bool,
        label: @escaping (T) -> String,
        icon: @escaping (T) -> String,
        tint: @escaping (T) -> Color,
        fill: @escaping (T) -> Color,
        onTap: @escaping (T) -> Void
    ) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Button { onTap(item) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: icon(item))
                            .font(.system(size: 11, weight: .semibold))
                        Text(label(item))
                            .font(AppTypography.caption.weight(.semibold))
                    }
                    .foregroundStyle(isSelected(item) ? tint(item) : AppColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isSelected(item) ? fill(item) : AppColors.surface)
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(isSelected(item) ? tint(item).opacity(0.5) : AppColors.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - FlowLayout
/// Simple wrap-to-next-line layout so chips don't overflow narrow widths.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x)
        }
        return CGSize(width: min(totalWidth, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x - bounds.minX + size.width > maxWidth {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
