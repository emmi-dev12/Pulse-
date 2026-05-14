import Foundation

struct TranscriptionRecord: Codable, Identifiable {
    let _id: String
    let _creationTime: Double
    let text: String
    let deviceId: String
    let createdAt: Double
    let duration: Double?

    var id: String { _id }
    var date: Date { Date(timeIntervalSince1970: createdAt / 1000) }
}

struct ConvexQueryResponse<T: Decodable>: Decodable {
    let status: String
    let value: T?
    let errorMessage: String?
}

struct ConvexMutationResponse: Decodable {
    let status: String
    let value: String?       // returned document ID
    let errorMessage: String?
}

enum ConvexError: Error {
    case noCredentials
    case networkError(Error)
    case apiError(String)
    case decodingError
}
