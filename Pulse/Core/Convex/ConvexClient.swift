import Foundation

@MainActor
final class ConvexClient: ObservableObject {
    @Published var isOnline: Bool = true

    private let keychain = KeychainService()
    private var pollingTimer: Timer?
    private(set) var lastSuccessfulPollTime: Date?

    var onTranscriptionsUpdated: (([TranscriptionRecord]) -> Void)?

    // MARK: - Polling

    func startPolling(intervalSeconds: Double = 5.0) {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] _ in
            Task { [weak self] in await self?.fetchTranscriptions() }
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: - Public API

    func fetchTranscriptions() async {
        do {
            let records: [TranscriptionRecord] = try await query(path: "transcriptions:list", args: ["limit": 100]) ?? []
            lastSuccessfulPollTime = Date()
            isOnline = true
            onTranscriptionsUpdated?(records)
        } catch {
            await checkOnlineStatus()
        }
    }

    func insertTranscription(text: String, deviceId: String, createdAt: Double, duration: Double?) async throws -> String {
        var args: [String: Any] = [
            "text": text,
            "deviceId": deviceId,
            "createdAt": createdAt
        ]
        if let duration { args["duration"] = duration }
        return try await mutation(path: "transcriptions:insert", args: args)
    }

    func deleteTranscription(id: String) async throws {
        _ = try await mutation(path: "transcriptions:deleteRecord", args: ["id": id])
    }

    func testConnection() async -> Bool {
        guard let urlString = keychain.load(.convexURL),
              let deployKey = keychain.load(.convexDeployKey),
              let url = URL(string: urlString + "/api/query") else { return false }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Convex \(deployKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "path": "transcriptions:list",
            "args": ["limit": 1],
            "format": "json"
        ])

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse else { return false }

        if http.statusCode == 401 { return false }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if (json["status"] as? String) == "success" { return true }
            // "Could not find public function" means credentials are valid, backend not deployed yet
            if let msg = json["errorMessage"] as? String, msg.contains("Could not find") { return true }
        }
        return http.statusCode < 500
    }

    // MARK: - HTTP Internals

    private func query<T: Decodable>(path: String, args: [String: Any]) async throws -> T? {
        guard let urlString = keychain.load(.convexURL),
              let deployKey = keychain.load(.convexDeployKey),
              let url = URL(string: urlString + "/api/query")
        else { throw ConvexError.noCredentials }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Convex \(deployKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["path": path, "args": args, "format": "json"])

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ConvexQueryResponse<T>.self, from: data)
        if response.status != "success" {
            throw ConvexError.apiError(response.errorMessage ?? "unknown")
        }
        return response.value
    }

    @discardableResult
    private func mutation(path: String, args: [String: Any]) async throws -> String {
        guard let urlString = keychain.load(.convexURL),
              let deployKey = keychain.load(.convexDeployKey),
              let url = URL(string: urlString + "/api/mutation")
        else { throw ConvexError.noCredentials }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Convex \(deployKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["path": path, "args": args, "format": "json"])

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ConvexMutationResponse.self, from: data)
        if response.status != "success" {
            throw ConvexError.apiError(response.errorMessage ?? "unknown")
        }
        return response.value ?? ""
    }

    private func checkOnlineStatus() async {
        let stale = lastSuccessfulPollTime.map { Date().timeIntervalSince($0) > 30 } ?? true
        isOnline = !stale
    }
}
