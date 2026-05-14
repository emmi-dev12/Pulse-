import Foundation

enum TranscriptionError: Error, LocalizedError {
    case noCredentials
    case networkError(Error)
    case decodingError
    case apiError(String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .noCredentials:    return "Composio API key not configured."
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .decodingError:    return "Unexpected response format from Composio."
        case .apiError(let m):  return "Composio error: \(m)"
        case .emptyResponse:    return "No transcript returned."
        }
    }
}

// Composio response envelope:
// { "execution_details": { "executed": true },
//   "response_data": { "result": { "transcription": { "full_transcript": "..." } } } }

private struct ComposioResponse: Decodable {
    struct ExecutionDetails: Decodable { let executed: Bool }
    struct ResponseData: Decodable {
        struct Result: Decodable {
            struct Transcription: Decodable { let full_transcript: String }
            let transcription: Transcription?
        }
        let result: Result?
    }
    let execution_details: ExecutionDetails?
    let response_data: ResponseData?
}

final class ComposioTranscriptionService {
    private let keychain = KeychainService()
    private let endpoint = "https://backend.composio.dev/api/v2/actions/GLADIA_TRANSCRIBE_AUDIO/execute"

    func transcribe(audioURL: URL) async throws -> String {
        guard let apiKey = keychain.load(.composioAPIKey) else {
            throw TranscriptionError.noCredentials
        }

        defer { try? FileManager.default.removeItem(at: audioURL) }

        let audioData: Data
        do { audioData = try Data(contentsOf: audioURL) }
        catch { throw TranscriptionError.networkError(error) }

        let base64Audio = audioData.base64EncodedString()

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "input": [
                "audio": base64Audio,
                "audio_format": "wav",
                "language_behaviour": "automatic single language",
                "output_format": "json"
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        do {
            let (d, _) = try await URLSession.shared.data(for: request)
            data = d
        } catch {
            throw TranscriptionError.networkError(error)
        }

        let decoded: ComposioResponse
        do { decoded = try JSONDecoder().decode(ComposioResponse.self, from: data) }
        catch {
            // Log raw response to stderr for debugging
            if let raw = String(data: data, encoding: .utf8) {
                fputs("Composio raw response: \(raw)\n", stderr)
            }
            throw TranscriptionError.decodingError
        }

        guard let transcript = decoded.response_data?.result?.transcription?.full_transcript,
              !transcript.isEmpty
        else { throw TranscriptionError.emptyResponse }

        return transcript
    }
}
