//
//  TranscriptionService.swift
//  Clarity
//
//  Phase 7 — wraps WhisperKit and exposes a friendly state machine to the UI.
//  The model (`openai_whisper-base.en`) is downloaded on first prepare,
//  then cached by WhisperKit. After preparation completes the service emits
//  a one-shot "ready" event so the app can surface a banner.
//

import Foundation
import Observation
import WhisperKit

@Observable
@MainActor
final class TranscriptionService {

    enum State: Equatable {
        case idle
        case preparing
        case ready
        case transcribing
        case failed(String)
    }

    private(set) var state: State = .idle
    /// Set to `true` once after the first time prepare() succeeds.
    /// The UI consumes + clears this to show a one-time "Voice is ready" banner.
    var pendingReadyAnnouncement: Bool = false

    private var whisperKit: WhisperKit?
    private let modelVariant = "openai_whisper-base.en"

    var isReady: Bool {
        if case .ready = state { return true }
        return false
    }

    // MARK: - Lifecycle

    /// Kicks off the model download + load if it hasn't started yet.
    /// Safe to call repeatedly; subsequent calls are no-ops.
    func prepareIfNeeded() async {
        switch state {
        case .preparing, .ready, .transcribing:
            return
        default:
            break
        }

        state = .preparing
        do {
            let config = WhisperKitConfig(
                model: modelVariant,
                verbose: false,
                logLevel: .error,
                prewarm: true,
                load: true,
                download: true
            )
            let kit = try await WhisperKit(config)
            self.whisperKit = kit
            self.state = .ready
            self.pendingReadyAnnouncement = true
        } catch {
            self.state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Transcription

    func transcribe(_ url: URL) async -> Result<String, Error> {
        guard let whisperKit else {
            return .failure(TranscriptionError.notReady)
        }
        state = .transcribing
        do {
            let results = try await whisperKit.transcribe(audioPath: url.path)
            let text = results
                .map(\.text)
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            state = .ready
            return .success(text)
        } catch {
            state = .failed(error.localizedDescription)
            return .failure(error)
        }
    }
}

enum TranscriptionError: LocalizedError {
    case notReady
    case empty

    var errorDescription: String? {
        switch self {
        case .notReady: return "The transcription model isn't ready yet. Hang on a moment."
        case .empty:    return "I couldn't make out any speech."
        }
    }
}
