//
//  AudioRecorder.swift
//  Clarity
//
//  Phase 7 — captures audio via AVAudioRecorder at 16 kHz mono PCM
//  (the format WhisperKit expects). Exposes live RMS levels for the
//  waveform and elapsed time for the timer.
//
//  iOS only for now; macOS audio plumbing arrives in a later phase
//  (needs a sandbox mic entitlement).
//

#if os(iOS)
import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class AudioRecorder: NSObject {

    enum State: Equatable {
        case idle
        case requestingPermission
        case denied
        case recording
        case finished(URL)
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var elapsedSeconds: TimeInterval = 0
    /// Recent normalized RMS levels (0…1), oldest first. Drives the waveform.
    private(set) var levels: [Float] = []

    private let maxLevels = 80
    private var recorder: AVAudioRecorder?
    private var meterTask: Task<Void, Never>?
    private var startedAt: Date?

    // MARK: - Public API

    func reset() {
        stopMeterLoop()
        recorder?.stop()
        recorder = nil
        elapsedSeconds = 0
        levels = []
        state = .idle
    }

    func start() async {
        guard state != .recording, state != .requestingPermission else { return }

        elapsedSeconds = 0
        levels = []

        state = .requestingPermission
        let granted = await Self.requestPermission()
        guard granted else {
            state = .denied
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord,
                                    mode: .measurement,
                                    options: [.allowBluetoothHFP, .defaultToSpeaker])
            try session.setActive(true)

            let url = FileManager.default
                .temporaryDirectory
                .appendingPathComponent("clarity-brain-dump-\(UUID().uuidString).wav")

            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 16_000.0,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false
            ]

            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            guard recorder.prepareToRecord(), recorder.record() else {
                state = .failed("Could not start recording.")
                return
            }

            self.recorder = recorder
            self.startedAt = Date()
            state = .recording
            startMeterLoop()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func stop() {
        guard let recorder, state == .recording else { return }
        let url = recorder.url
        recorder.stop()
        stopMeterLoop()
        self.recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        state = .finished(url)
    }

    // MARK: - Helpers

    private func startMeterLoop() {
        meterTask?.cancel()
        meterTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.tick()
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    private func stopMeterLoop() {
        meterTask?.cancel()
        meterTask = nil
    }

    private func tick() {
        guard let recorder else { return }
        recorder.updateMeters()
        let dB = recorder.averagePower(forChannel: 0)
        // Map -60 dB…0 dB → 0…1, then bias slightly so silence still has a faint shimmer.
        let normalized = max(0, min(1, (dB + 60) / 60))
        levels.append(normalized)
        if levels.count > maxLevels {
            levels.removeFirst(levels.count - maxLevels)
        }
        if let startedAt {
            elapsedSeconds = Date().timeIntervalSince(startedAt)
        }
    }

    private static func requestPermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { cont in
                AVAudioApplication.requestRecordPermission { granted in
                    cont.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }
}

extension AudioRecorder {
    /// `0:23` style, monospaced-friendly.
    var elapsedLabel: String {
        let total = Int(elapsedSeconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
#endif
