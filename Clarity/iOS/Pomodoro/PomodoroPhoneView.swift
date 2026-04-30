//
//  PomodoroView.swift  (iOS)
//  Clarity
//
//  Phone-friendly version of the cinematic Pomodoro tab. Same dark vibe and
//  cosmic hero, but stacked: top bar → hero → phase timeline → mode picker
//  → today's focus → sessions → end-session button. The Current Task card
//  also collapses into a compact pill on phone.
//

#if os(iOS)
import SwiftUI

struct PomodoroView: View {
    @Environment(FocusEngine.self) private var engine
    @Environment(TaskStore.self) private var store

    @State private var showTaskPicker: Bool = false

    var body: some View {
        ZStack {
            // Cosmic atmosphere runs behind the entire scroll view —
            // stars + nebula bleed across all panels, not just the hero.
            CosmicBackdrop().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    topBar
                        .padding(.horizontal, 18)
                        .padding(.top, 6)

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
                    .frame(height: 380)
                    .padding(.horizontal, 16)

                    VStack(spacing: 4) {
                        Text("Current Phase")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                        Text(engine.phase.title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.accentColor)
                        Text(engine.phase.strapline)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    PhaseTimeline(mode: engine.mode, currentPhase: engine.phase)
                        .padding(.horizontal, 12)

                    CurrentTaskCard(
                        task: boundTask,
                        projectName: boundProject?.name,
                        projectColor: boundProject?.accentColor,
                        onPick: { showTaskPicker = true }
                    )
                    .padding(.horizontal, 16)

                    panels
                        .padding(.horizontal, 16)

                    EndSessionButton { engine.endSession() }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
            }
        }
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showTaskPicker) {
            FocusTaskPickerSheet(currentTaskID: engine.boundTaskID) { task in
                engine.boundTaskID = task?.id
                engine.boundTaskTitle = task?.title
            }
            .environment(store)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var panels: some View {
        @Bindable var engineRef = engine
        VStack(spacing: 12) {
            ModePickerCard(selected: $engineRef.mode)
            TodaysFocusCard(focusMinutes: engine.todaysFocusMinutes,
                            goalMinutes: engine.dailyGoalMinutes)
            SessionsListCard(sessions: engine.todaysSessions, goalCount: 8)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                showTaskPicker = true
            } label: {
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
            Spacer()
            modeSegmented
        }
    }

    private var modeSegmented: some View {
        HStack(spacing: 4) {
            segmented(.pomodoro)
            segmented(.deepWork)
        }
        .padding(4)
        .background(Capsule().fill(Color.white.opacity(0.04)))
        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func segmented(_ mode: FocusMode) -> some View {
        let isOn = engine.mode == mode
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                engine.mode = mode
            }
        } label: {
            Text(mode.title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(isOn ? .white : .white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(isOn ? Color.accentColor.opacity(0.45) : .clear))
                .overlay(Capsule().stroke(isOn ? Color.accentColor.opacity(0.7) : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

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
