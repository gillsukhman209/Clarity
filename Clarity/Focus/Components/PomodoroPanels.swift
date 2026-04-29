//
//  PomodoroPanels.swift
//  Clarity
//
//  Right-column cards on the Pomodoro tab: Today's Focus ring,
//  Sessions list, Mode picker, End Session button. Plus the bottom
//  Current Task card. Kept in one file because they all share the
//  same dark-card visual language and there's no reason to split.
//

import SwiftUI

// MARK: - Today's focus ring

struct TodaysFocusCard: View {
    let focusMinutes: Int
    let goalMinutes: Int

    private var progress: Double {
        guard goalMinutes > 0 else { return 0 }
        return min(1, Double(focusMinutes) / Double(goalMinutes))
    }

    var body: some View {
        DarkPanel {
            VStack(spacing: 14) {
                Text("TODAY'S FOCUS")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    DotRing(progress: progress)
                        .frame(width: 200, height: 200)
                    VStack(spacing: 4) {
                        Text("Focus Time")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                        Text(timeLabel)
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                        Text("of \(goalLabel) goal")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                .padding(.vertical, 4)

                Text("Every hour of focus\nmoves the needle forward.")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var timeLabel: String {
        let h = focusMinutes / 60
        let m = focusMinutes % 60
        if h == 0 { return "\(m)m" }
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    private var goalLabel: String {
        let h = goalMinutes / 60
        return "\(h)h"
    }
}

/// Particle-style ring made of small dots that fill clockwise to indicate
/// progress. Uses a Canvas so we can draw 80+ dots without spawning views.
private struct DotRing: View {
    let progress: Double
    var dotCount: Int = 84

    var body: some View {
        Canvas { ctx, size in
            let radius = min(size.width, size.height) / 2 - 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let active = Int(Double(dotCount) * progress)

            for i in 0..<dotCount {
                let angle = Double(i) / Double(dotCount) * .pi * 2 - .pi / 2
                let r = radius - (i.isMultiple(of: 6) ? 2 : 0)
                let x = center.x + cos(angle) * r
                let y = center.y + sin(angle) * r
                let isActive = i < active
                let dotR: CGFloat = isActive ? 1.8 : 1.2
                let alpha: Double = isActive ? 0.95 : 0.18
                let color = isActive
                    ? PomodoroPalette.accent
                    : Color.white
                let rect = CGRect(x: x - dotR, y: y - dotR, width: dotR * 2, height: dotR * 2)
                ctx.fill(Path(ellipseIn: rect), with: .color(color.opacity(alpha)))

                if isActive {
                    let glowR = dotR * 3
                    let glowRect = CGRect(x: x - glowR, y: y - glowR, width: glowR * 2, height: glowR * 2)
                    ctx.fill(Path(ellipseIn: glowRect), with: .color(color.opacity(0.18)))
                }
            }
        }
    }
}

// MARK: - Sessions list

struct SessionsListCard: View {
    let sessions: [FocusSession]
    let goalCount: Int

    var body: some View {
        DarkPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("SESSIONS")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    Text("\(sessions.count) / \(goalCount)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }

                if sessions.isEmpty {
                    Text("Sessions you complete today will appear here.")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.vertical, 6)
                } else {
                    VStack(spacing: 10) {
                        ForEach(sessions) { sess in
                            sessionRow(sess)
                        }
                    }
                }
            }
        }
    }

    private func sessionRow(_ s: FocusSession) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 30, height: 30)
                Image(systemName: s.completedAt != nil ? "checkmark.seal.fill" : "timer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(s.taskTitle ?? s.mode.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(s.startTimeLabel)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Text(s.minutesLabel)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .monospacedDigit()
            Image(systemName: s.completedAt != nil ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(s.completedAt != nil ? PomodoroPalette.accent : Color.white.opacity(0.2))
        }
    }
}

// MARK: - Mode picker

struct ModePickerCard: View {
    @Binding var selected: FocusMode

    var body: some View {
        DarkPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("MODE")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.55))

                ForEach(FocusMode.allCases) { mode in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                            selected = mode
                        }
                    } label: {
                        modeRow(mode, isSelected: selected == mode)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func modeRow(_ mode: FocusMode, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(isSelected ? PomodoroPalette.accent : Color.white.opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(isSelected ? PomodoroPalette.accent.opacity(0.15) : Color.white.opacity(0.04)))
                Image(systemName: mode.sfSymbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? PomodoroPalette.accent : Color.white.opacity(0.6))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(mode.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(mode.subtitle)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(PomodoroPalette.accent)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? PomodoroPalette.accent.opacity(0.10) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? PomodoroPalette.accent.opacity(0.45) : Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - End session button

struct EndSessionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("End Session")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(PomodoroPalette.coral)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(PomodoroPalette.coral.opacity(0.55), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Current task card (bottom of main column)

struct CurrentTaskCard: View {
    let task: PlanTask?
    let projectName: String?
    let projectColor: Color?
    var onPick: () -> Void = {}

    var body: some View {
        DarkPanel(padding: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CURRENT TASK")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.55))

                    Text(task?.title ?? "No task selected")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    if let projectName, let projectColor {
                        HStack(spacing: 6) {
                            Circle().fill(projectColor).frame(width: 6, height: 6)
                            Text(projectName)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(projectColor)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(projectColor.opacity(0.16)))
                        .overlay(Capsule().stroke(projectColor.opacity(0.4), lineWidth: 1))
                    }
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 8) {
                    if let task, task.durationMinutes > 0 {
                        Text("Est. \(task.durationMinutes) min")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Button(action: onPick) {
                        Image(systemName: task == nil ? "plus" : "pencil")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.white.opacity(0.06)))
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Shared dark panel container

struct DarkPanel<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.025))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
    }
}
