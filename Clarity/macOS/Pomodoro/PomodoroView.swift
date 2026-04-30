//
//  PomodoroView.swift  (macOS)
//  Clarity
//
//  Cinematic dark Pomodoro tab. Lays out:
//    [ main hero column         | right stats column ]
//
//  Main column (top→bottom):
//    - Top bar: mode dropdown · Pomodoro/Deep Work segmented · audio + ⋯
//    - Cosmic hero (planet + rings + countdown)
//    - "Current Phase" label + strapline
//    - Phase timeline (Focus → Short Break → Long Break → Complete)
//    - Current task card
//
//  Right column:
//    - Today's Focus ring
//    - Sessions list
//    - Mode picker
//    - End Session button
//

#if os(macOS)
import SwiftUI

struct PomodoroView: View {
    @Environment(FocusEngine.self) private var engine
    @Environment(TaskStore.self) private var store

    @State private var showTaskPicker: Bool = false

    var body: some View {
        // No background fill here — MacRootView provides the unified
        // PomodoroPalette.space across the whole window when on this tab.
        HStack(alignment: .top, spacing: 24) {
            mainColumn
                .frame(maxWidth: .infinity)
            rightColumn
                .frame(width: 320)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
        .sheet(isPresented: $showTaskPicker) {
            FocusTaskPickerSheet(currentTaskID: engine.boundTaskID) { task in
                engine.boundTaskID = task?.id
                engine.boundTaskTitle = task?.title
            }
            .environment(store)
        }
    }

    // MARK: - Main column

    @ViewBuilder
    private var mainColumn: some View {
        VStack(spacing: 22) {
            topBar

            // Cosmic hero — bleeds edge-to-edge against the same black as the
            // rest of the app, so there's no visible card outline around it.
            // Each tick advances the engine: when a phase ends the engine
            // auto-rolls to the next phase and logs the session.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                CosmicHero(
                    phase: engine.phase,
                    progress: engine.progress(at: context.date),
                    countdown: engine.countdownLabel(at: context.date),
                    isPaused: engine.isPaused,
                    isIdle: !engine.hasActiveSession,
                    onTogglePause: { engine.togglePause() },
                    onStart: {
                        let task = boundTask
                        engine.start(taskID: task?.id, taskTitle: task?.title)
                    }
                )
                .onAppear { engine.tick(at: context.date) }
                .onChange(of: context.date) { _, new in engine.tick(at: new) }
            }
            .frame(minHeight: 360)
            .frame(maxHeight: .infinity)

            VStack(spacing: 6) {
                Text("Current Phase")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                Text(engine.phase.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(PomodoroPalette.accent)
                Text(engine.phase.strapline)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            PhaseTimeline(mode: engine.mode, currentPhase: engine.phase)

            CurrentTaskCard(
                task: boundTask,
                projectName: boundProject?.name,
                projectColor: boundProject?.accentColor,
                onPick: { showTaskPicker = true }
            )
        }
    }

    // MARK: - Right column

    @ViewBuilder
    private var rightColumn: some View {
        @Bindable var engineRef = engine
        VStack(spacing: 16) {
            TodaysFocusCard(
                focusMinutes: engine.todaysFocusMinutes,
                goalMinutes: engine.dailyGoalMinutes
            )
            SessionsListCard(
                sessions: engine.todaysSessions,
                goalCount: 8
            )
            ModePickerCard(selected: $engineRef.mode)
            EndSessionButton {
                engine.endSession()
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 16) {
            taskTitleButton
            Spacer()
            modeSegmented.frame(maxWidth: 280)
            Spacer()
            optionsMenu
        }
    }

    /// Tappable title that opens the task picker. When a task is bound,
    /// show its title; otherwise the mode title as a sensible default.
    private var taskTitleButton: some View {
        Button { showTaskPicker = true } label: {
            HStack(spacing: 6) {
                Text(engine.boundTaskTitle ?? engine.mode.title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Pick a task to focus on")
    }

    /// Three-dot menu for actions that don't need their own toolbar slot:
    /// pick task, skip phase, end session. All wired to real engine
    /// operations — no mock entries.
    private var optionsMenu: some View {
        Menu {
            Button {
                showTaskPicker = true
            } label: {
                Label(engine.boundTaskTitle == nil ? "Pick a task" : "Change task",
                      systemImage: "text.badge.checkmark")
            }
            if engine.hasActiveSession {
                Button {
                    if engine.phase == .focus {
                        // Skip the focus → break flips. We do NOT log a
                        // partial session for a skipped focus phase, since
                        // the user explicitly bailed.
                    }
                    engine.advancePhase()
                } label: {
                    Label("Skip to next phase", systemImage: "forward.end")
                }
                Button(role: .destructive) {
                    engine.endSession()
                } label: {
                    Label("End session", systemImage: "stop.circle")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.white.opacity(0.04)))
                .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var modeSegmented: some View {
        return HStack(spacing: 4) {
            segmentedButton(.pomodoro)
            segmentedButton(.deepWork)
        }
        .padding(4)
        .background(Capsule(style: .continuous).fill(Color.white.opacity(0.04)))
        .overlay(Capsule(style: .continuous).stroke(PomodoroPalette.accent.opacity(0.18), lineWidth: 1))
    }

    private func segmentedButton(_ mode: FocusMode) -> some View {
        let isOn = engine.mode == mode
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                engine.mode = mode
            }
        } label: {
            Text(mode.title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isOn ? .white : Color.white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(isOn ? PomodoroPalette.accentSoft : Color.clear)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isOn ? PomodoroPalette.accent.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var boundTask: PlanTask? {
        guard let id = engine.boundTaskID else { return nil }
        return store.task(with: id)
    }

    private var boundProject: Project? {
        guard let pid = boundTask?.projectID else { return nil }
        return store.project(with: pid)
    }
}
#endif
