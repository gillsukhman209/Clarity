//
//  ProjectEditorSheet.swift
//  Clarity
//
//  Sheet used to create a new project or edit an existing one.
//  Same UI for both — pass `editing` for edit mode.
//

import SwiftUI

struct ProjectEditorSheet: View {
    /// `nil` = create mode. Non-nil = edit the existing project.
    let editing: Project?
    var onClose: () -> Void = {}

    @Environment(TaskStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var iconSymbol: String = "folder.fill"
    @State private var colorHex: String = "8B7CF6"
    @FocusState private var nameFocused: Bool

    private var isEdit: Bool { editing != nil }

    private var accent: Color {
        Color(hex: colorHex) ?? AppColors.accent
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    preview
                    nameField
                    iconPicker
                    colorPicker
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.xl)
            }
            footer
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
        #if os(macOS)
        .frame(minWidth: 460, idealWidth: 500, minHeight: 540)
        #endif
        .background(AppColors.background)
        .onAppear {
            if let editing {
                name = editing.name
                iconSymbol = editing.iconSymbol
                colorHex = editing.colorHex
            }
            nameFocused = true
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
            Text(isEdit ? "Edit Project" : "New Project")
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

    // MARK: - Preview
    private var preview: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accent.opacity(0.18))
                    .frame(width: 56, height: 56)
                Image(systemName: iconSymbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? (isEdit ? "Untitled" : "New project") : name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                Text("Preview")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .fill(AppColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .stroke(AppColors.border.opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Name
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Name")
            TextField("Project name", text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .focused($nameFocused)
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
                .submitLabel(.done)
                .onSubmit { if canSave { save() } }
        }
    }

    // MARK: - Icon picker
    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("Icon")
            let cols = Array(repeating: GridItem(.flexible(minimum: 40), spacing: 10), count: 8)
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(ProjectPalette.icons, id: \.self) { sym in
                    Button { iconSymbol = sym } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(iconSymbol == sym ? accent.opacity(0.18) : AppColors.surface)
                            Image(systemName: sym)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(iconSymbol == sym ? accent : AppColors.textSecondary)
                        }
                        .frame(height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(iconSymbol == sym ? accent.opacity(0.45) : AppColors.border.opacity(0.6), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Color picker
    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("Color")
            HStack(spacing: 10) {
                ForEach(ProjectPalette.colors, id: \.self) { hex in
                    let c = Color(hex: hex) ?? AppColors.accent
                    Button { colorHex = hex } label: {
                        ZStack {
                            Circle()
                                .fill(c)
                                .frame(width: 30, height: 30)
                            if colorHex == hex {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .heavy))
                                    .foregroundStyle(.white)
                            }
                        }
                        .overlay(
                            Circle()
                                .stroke(colorHex == hex ? AppColors.textPrimary.opacity(0.4) : Color.clear, lineWidth: 2)
                                .padding(-3)
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
    }

    // MARK: - Footer
    private var footer: some View {
        HStack(spacing: AppSpacing.sm) {
            if let editing {
                Button(role: .destructive) {
                    store.deleteProject(editing.id)
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
            }
            Spacer()
            Button { save() } label: {
                HStack(spacing: 6) {
                    Image(systemName: isEdit ? "checkmark" : "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text(isEdit ? "Save changes" : "Create project")
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
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(AppColors.textTertiary)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let editing {
            store.updateProject(editing.id, name: trimmed, iconSymbol: iconSymbol, colorHex: colorHex)
        } else {
            store.createProject(name: trimmed, iconSymbol: iconSymbol, colorHex: colorHex)
        }
        close()
    }

    private func close() {
        onClose()
        dismiss()
    }
}

private extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8)  & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
