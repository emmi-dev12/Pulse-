import Foundation
import Combine
import ApplicationServices

enum RecordingState: Equatable {
    case idle
    case recording
    case transcribing
    case error(String)
}

@MainActor
final class RecordingCoordinator: ObservableObject {
    @Published var state: RecordingState = .idle
    @Published var lastTranscript: String = ""
    @Published var history: [CachedTranscription] = []

    // Injected dependencies
    let audioRecorder = AudioRecorder()
    let convexClient = ConvexClient()
    private let hotKeyManager = GlobalHotKeyManager()
    private let transcriptionService = ComposioTranscriptionService()
    private let textInjection = TextInjectionService()
    private let cache = LocalCacheService()

    private var capturedElement: AXUIElement?
    private var cancellables = Set<AnyCancellable>()
    private let deviceId = getDeviceID()

    func start() {
        history = cache.load()

        hotKeyManager.onKeyDown = { [weak self] in
            Task { @MainActor [weak self] in self?.beginRecording() }
        }
        hotKeyManager.onKeyUp = { [weak self] in
            Task { @MainActor [weak self] in await self?.endRecording() }
        }
        hotKeyManager.start()

        convexClient.onTranscriptionsUpdated = { [weak self] records in
            Task { @MainActor [weak self] in self?.mergeServerRecords(records) }
        }
        convexClient.startPolling()
    }

    func stop() {
        hotKeyManager.stop()
        convexClient.stopPolling()
    }

    // MARK: - State machine

    private func beginRecording() {
        guard state == .idle else { return }
        capturedElement = textInjection.captureFocusedElement()
        state = .recording
        do {
            try audioRecorder.startRecording()
        } catch {
            state = .error("Microphone unavailable: \(error.localizedDescription)")
        }
    }

    private func endRecording() async {
        guard state == .recording else { return }
        state = .transcribing

        let start = Date()
        guard let audioURL = audioRecorder.stopRecording() else {
            state = .error("Recording failed.")
            return
        }
        let duration = Date().timeIntervalSince(start)

        do {
            let text = try await transcriptionService.transcribe(audioURL: audioURL)
            lastTranscript = text
            state = .idle

            // Inject into previously focused field
            let element = capturedElement
            capturedElement = nil
            textInjection.inject(text: text, into: element)

            // Persist locally first (always works, even offline)
            let record = CachedTranscription(
                id: UUID().uuidString,
                text: text,
                timestamp: Date(),
                syncedToConvex: false,
                convexID: nil,
                duration: duration
            )
            cache.append(record)
            history = cache.load()

            // Sync to Convex
            await syncToConvex(record: record)

            // Flush any other unsynced records
            await syncUnsyncedCache()

        } catch {
            state = .error(error.localizedDescription)
            capturedElement = nil
        }
    }

    // MARK: - Convex sync

    private func syncToConvex(record: CachedTranscription) async {
        do {
            let convexID = try await convexClient.insertTranscription(
                text: record.text,
                deviceId: deviceId,
                createdAt: record.timestamp.timeIntervalSince1970 * 1000,
                duration: record.duration
            )
            cache.markSynced(id: record.id, convexID: convexID)
        } catch {
            // Will retry in syncUnsyncedCache on next successful poll
        }
    }

    private func syncUnsyncedCache() async {
        let unsynced = cache.unsyncedRecords()
        for record in unsynced {
            await syncToConvex(record: record)
        }
    }

    private func mergeServerRecords(_ serverRecords: [TranscriptionRecord]) {
        var merged = history
        for server in serverRecords {
            if !merged.contains(where: { $0.convexID == server._id }) {
                let cached = CachedTranscription(
                    id: UUID().uuidString,
                    text: server.text,
                    timestamp: server.date,
                    syncedToConvex: true,
                    convexID: server._id,
                    duration: server.duration
                )
                merged.append(cached)
            }
        }
        merged.sort { $0.timestamp > $1.timestamp }
        history = merged
        cache.save(merged)
    }
}

private func getDeviceID() -> String {
    let key = "pulse.deviceID"
    if let existing = UserDefaults.standard.string(forKey: key) { return existing }
    let newID = UUID().uuidString
    UserDefaults.standard.set(newID, forKey: key)
    return newID
}
