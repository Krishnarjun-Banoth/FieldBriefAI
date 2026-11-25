import Foundation

// Separate protocol keeps the user experience testable without making a network call.
struct GeneratedBrief {
    let document: FieldBrief
    let route: InferenceRoute
}

@MainActor
protocol BriefAIProcessing {
    var onDeviceAvailable: Bool { get }
    var onDeviceStatus: String { get }
    func generate(note: String, allowCloud: Bool, visitContext: String?) async throws -> GeneratedBrief
}

enum BriefProcessingError: Error, LocalizedError {
    case onDeviceUnavailable
    case missingFirebaseConfiguration

    var errorDescription: String? {
        switch self {
        case .onDeviceUnavailable:
            return "Apple Intelligence is unavailable. Enable it on a compatible device or explicitly allow cloud fallback."
        case .missingFirebaseConfiguration:
            return "Firebase isn't configured. Follow the README setup steps first."
        }
    }
}
