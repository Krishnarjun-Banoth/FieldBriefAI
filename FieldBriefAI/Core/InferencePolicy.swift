import Foundation

public enum InferenceMode: Equatable, Sendable {
    case blocked
    case onDeviceOnly
    case hybridWithCloudConsent
}

/// Explicit, testable routing policy. Cloud must never be selected without consent.
public enum InferencePolicy {
    public static func mode(localAvailable: Bool, cloudConsented: Bool) -> InferenceMode {
        if cloudConsented { return .hybridWithCloudConsent }
        return localAvailable ? .onDeviceOnly : .blocked
    }
}

public enum InferenceRoute: Equatable, Sendable {
    case onDevice
    case cloud(model: String)
    case unknown

    public static func reported(modelVersion: String) -> InferenceRoute {
        if modelVersion == "apple-foundation-models-system-language-model" { return .onDevice }
        if modelVersion.isEmpty || modelVersion == "unknown-model-version" { return .unknown }
        return .cloud(model: modelVersion)
    }

    public var displayName: String {
        switch self {
        case .onDevice: return "Processed on this iPhone"
        case .cloud(let model): return "Processed with Gemini (\(model))"
        case .unknown: return "Processing route not reported"
        }
    }
}
