//
//  AudioRecorder.swift
//  Clarity
//
//  Phase 7 — capture audio at 16 kHz mono PCM (what WhisperKit expects).
//  Phase 11 — cross-platform: iOS uses AVAudioSession + AVAudioApplication
//  for permissions; macOS uses AVCaptureDevice and skips the audio session.
//
//  Phase 13 — emits a `silent` failure if the recording was empty / no signal.
//

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
    /// Peak level seen during the recording. Used to detect "silent" recordings.
    private var peakLevel: Float = 0

    // MARK: - Public API

    func reset() {
        stopMeterLoop()
        recorder?.stop()
        recorder = nil
        elapsedSeconds = 0
        levels = []
        peakLevel = 0
        state = .idle
    }

    func start() async {
        guard state != .recording, state != .requestingPermission else { return }

        elapsedSeconds = 0
        levels = []
        peakLevel = 0

        state = .requestingPermission
        let granted = await Self.requestPermission()
        guard granted else {
            state = .denied
            return
        }

        do {
            #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord,
                                    mode: .measurement,
                                    options: [.allowBluetoothHFP, .defaultToSpeaker])
            try session.setActive(true)
            #endif

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

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif

        // Phase 13: catch silent / no-signal recordings up front so we don't
        // round-trip them through Whisper for nothing.
        if elapsedSeconds < 0.6 {
            state = .failed("That was too short. Try holding the mic and speaking for a moment.")
            try? FileManager.default.removeItem(at: url)
            return
        }
        if peakLevel < 0.05 {
            state = .failed("I couldn't hear anything — check your mic and try again.")
            try? FileManager.default.removeItem(at: url)
            return
        }

        state = .finished(url)
    }

    // MARK: - Helpers

    private func startMeterLoop() {
        meterTask?.cancel()
        meterTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.tick()
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
        let normalized = max(0, min(1, (dB + 60) / 60))
        levels.append(normalized)
        if levels.count > maxLevels {
            levels.removeFirst(levels.count - maxLevels)
        }
        peakLevel = max(peakLevel, normalized)
        if let startedAt {
            elapsedSeconds = Date().timeIntervalSince(startedAt)
        }
    }

    // MARK: - Permission

    private static func requestPermission() async -> Bool {
        #if os(iOS)
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
        #else
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await withCheckedContinuation { cont in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    cont.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
        #endif
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
