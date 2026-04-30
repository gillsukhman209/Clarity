//
//  FocusDurationsEditor.swift
//  Clarity
//
//  Popover for tweaking the minute counts of a Pomodoro / Deep Work mode.
//  Three rows — Focus, Short Break, Long Break — each with stepper + value.
//  A Reset button drops the mode back to its built-in defaults.
//

import SwiftUI

struct FocusDurationsEditor: View {
    let mode: FocusMode
    @Environment(FocusSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    private var current: FocusDurations { settings.durations(for: mode) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider().background(AppColors.divider)
            row(
                title: "Focus",
                value: current.focusMinutes,
                range: 1...180,
                step: 5
            ) { newValue in
                update { $0.focusMinutes = newValue }
            }
            row(
                title: "Short Break",
                value: current.shortBreakMinutes,
                range: 1...30,
                step: 1
            ) { newValue in
                update { $0.shortBreakMinutes = newValue }
            }
            row(
                title: "Long Break",
                value: current.longBreakMinutes,
                range: 1...60,
                step: 5
            ) { newValue in
                update { $0.longBreakMinutes = newValue }
            }
            row(
                title: "Cycles before long break",
                value: current.cyclesBeforeLongBreak,
                range: 2...8,
                step: 1,
                unit: ""
            ) { newValue in
                update { $0.cyclesBeforeLongBreak = newValue }
            }
            Divider().background(AppColors.divider)
            footer
        }
        .padding(18)
        #if os(macOS)
        .frame(width: 320)
        #else
        .frame(maxWidth: 360)
        #endif
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.background)
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: mode.sfSymbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.accent)
            Text("Customize \(mode.title)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
        }
    }

    // MARK: - Row

    private func row(
        title: String,
        value: Int,
        range: ClosedRange<Int>,
        step: Int,
        unit: String = "min",
        onChange: @escaping (Int) -> Void
    ) -> some View {
        let binding = Binding<Int>(
            get: { value },
            set: { onChange(min(range.upperBound, max(range.lowerBound, $0))) }
        )
        return HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            HStack(spacing: 4) {
                Text(unit.isEmpty ? "\(value)" : "\(value) \(unit)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .monospacedDigit()
                    .frame(minWidth: 56, alignment: .trailing)
                Stepper("", value: binding, in: range, step: step)
                    .labelsHidden()
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Button {
                settings.resetToDefaults(for: mode)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Reset")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(AppColors.surface))
                .overlay(Capsule().stroke(AppColors.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(AppColors.accent))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func update(_ mutate: (inout FocusDurations) -> Void) {
        var d = current
        mutate(&d)
        settings.update(d, for: mode)
    }
}
