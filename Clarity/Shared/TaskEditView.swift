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

    @State private var showDatePopover: Bool = false
    @State private var showTimePopover: Bool = false
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
        .frame(minWidth: 480, idealWidth: 540, minHeight: 600)
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
                VStack(alignment: .leading, spacing: 22) {
                    titleField
                    categoryRow
                    priorityRow
                    whenRow
                    durationRow
                    notesField
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.lg)
            }

            footer(for: task)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .background(
                    AppColors.surface.opacity(0.5)
                        .overlay(
                            Rectangle().fill(AppColors.divider).frame(height: 1),
                            alignment: .top
                        )
                )
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
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - Title
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Title")
            TextField("Title", text: $title, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1...3)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColors.border.opacity(0.7), lineWidth: 1)
                )
        }
    }

    // MARK: - Category
    private var categoryRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("Category")
            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(TaskCategory.allCases) { cat in
                    Button { category = cat } label: {
                        HStack(spacing: 6) {
                            Image(systemName: cat.sfSymbol)
                                .font(.system(size: 11, weight: .semibold))
                            Text(cat.title)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(category == cat ? cat.inkColor : AppColors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule(style: .continuous)
                                .fill(category == cat ? cat.fillColor.opacity(0.65) : AppColors.surface)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(category == cat ? cat.inkColor.opacity(0.45) : AppColors.border.opacity(0.7), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Priority
    private var priorityRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("Priority")
            HStack(spacing: 8) {
                ForEach(TaskPriority.allCases, id: \.self) { p in
                    priorityChip(p)
                }
            }
        }
    }

    private func priorityChip(_ p: TaskPriority) -> some View {
        let isOn = priority == p
        return Button { priority = p } label: {
            Text(p.title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isOn ? p.inkColor : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(isOn ? p.fillColor.opacity(0.65) : AppColors.surface)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isOn ? p.inkColor.opacity(0.45) : AppColors.border.opacity(0.7), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - When (date + optional time, popover-driven)
    private var whenRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                fieldLabel("When")
                Spacer()
                Toggle("", isOn: $hasTime.animation(.easeInOut(duration: 0.18)))
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                Text("Set time")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }
            HStack(spacing: 8) {
                datePill
                if hasTime {
                    timePill
                } else {
                    anytimeBadge
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var datePill: some View {
        Button { showDatePopover.toggle() } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
                Text(dateString)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous).fill(AppColors.surface)
            )
            .overlay(
                Capsule(style: .continuous).stroke(AppColors.border.opacity(0.7), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showDatePopover, arrowEdge: .bottom) {
            DatePicker("", selection: $startDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .frame(minWidth: 280, minHeight: 280)
                .padding(12)
        }
    }

    private var timePill: some View {
        Button { showTimePopover.toggle() } label: {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
                Text(timeString)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous).fill(AppColors.surface)
            )
            .overlay(
                Capsule(style: .continuous).stroke(AppColors.border.opacity(0.7), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showTimePopover, arrowEdge: .bottom) {
            VStack(spacing: 10) {
                Text("Time")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textTertiary)
                DatePicker("", selection: $startDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
            }
            .padding(16)
            .frame(minWidth: 220)
        }
    }

    private var anytimeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "infinity")
                .font(.system(size: 11, weight: .semibold))
            Text("Anytime")
                .font(.system(size: 13, weight: .medium, design: .rounded))
        }
        .foregroundStyle(AppColors.textTertiary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous).fill(AppColors.surface.opacity(0.6))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AppColors.border.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        )
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: startDate)
    }

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: startDate)
    }

    // MARK: - Duration (uniform-width chips, no stepper)
    private var durationRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("Duration")
            HStack(spacing: 6) {
                durationChip(label: "None", value: 0)
                ForEach(durationPresets, id: \.self) { mins in
                    durationChip(label: durationPresetLabel(mins), value: mins)
                }
            }
        }
    }

    private let durationPresets: [Int] = [15, 30, 45, 60, 90, 120]

    private func durationChip(label: String, value: Int) -> some View {
        let isOn = durationMinutes == value
        return Button { durationMinutes = value } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isOn ? .white : AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(isOn ? AppColors.accent : AppColors.surface)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isOn ? AppColors.accent : AppColors.border.opacity(0.7), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func durationPresetLabel(_ mins: Int) -> String {
        if mins < 60 { return "\(mins)m" }
        let h = mins / 60
        let m = mins % 60
        return m == 0 ? "\(h)h" : "\(h)h\(m)"
    }

    // MARK: - Notes
    private var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Notes")
            TextField("Anything to remember", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2...8)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColors.border.opacity(0.7), lineWidth: 1)
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
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(AppColors.Priority.highInk)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Capsule(style: .continuous)
                        .stroke(AppColors.Priority.highInk.opacity(0.35), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Spacer()

            Button { save() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Save changes")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
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

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(AppColors.textTertiary)
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
}

// MARK: - FlowLayout
/// Wrap-to-next-line layout for chip rows (e.g. category picker).
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                y += rowHeight + lineSpacing
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
                y += rowHeight + lineSpacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
