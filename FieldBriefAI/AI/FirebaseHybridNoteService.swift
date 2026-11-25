import Foundation
import FirebaseAILogic
import FoundationModels

/// This is a real Firebase AI Logic runtime integration, not a mocked demo.
/// Its hybrid session is created only after the user opts in to cloud fallback.
@MainActor
struct FirebaseHybridNoteService: BriefAIProcessing {
    var onDeviceAvailable: Bool {
        FoundationModels.SystemLanguageModel.default.isAvailable
    }

    var onDeviceStatus: String {
        switch FoundationModels.SystemLanguageModel.default.availability {
        case .available:
            return "Apple Intelligence is available for local inference."
        case .unavailable(.deviceNotEligible):
            return "This device is ineligible for Apple Intelligence."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Enable Apple Intelligence in Settings to generate briefs locally."
        case .unavailable(.modelNotReady):
            return "Wait for Apple Intelligence to finish downloading its on-device model."
        case .unavailable:
            return "Apple Intelligence is currently unavailable."
        }
    }

    func generate(note: String, allowCloud: Bool, visitContext: String?) async throws -> GeneratedBrief {
        let validated = try PromptBuilder.validatedNote(note)
        let prompt = PromptBuilder.makePrompt(note: validated, visitContext: visitContext)
        let localModel = FirebaseAI.SystemLanguageModel.default

        switch InferencePolicy.mode(localAvailable: localModel.isAvailable, cloudConsented: allowCloud) {
        case .hybridWithCloudConsent:
            guard AppConfiguration.isFirebaseReady else {
                throw BriefProcessingError.missingFirebaseConfiguration
            }
            let ai = FirebaseAI.firebaseAI(backend: .googleAI())
            let cloudModel = ai.geminiModel(name: "gemini-3.5-flash-lite")
            var session = ai.generativeModelSession(
                model: .hybridModel(primary: localModel, secondary: cloudModel)
            )
            #if DEBUG
            // Exercise real cloud inference after consent without changing device settings.
            if ProcessInfo.processInfo.arguments.contains("-testGeminiCloud") {
                session = ai.generativeModelSession(model: cloudModel)
            }
            #endif
            let response: GenerativeModelSession.Response<String>
            do {
                response = try await session.respond(to: prompt, options: FirebaseAI.GenerationOptions(
                    sampling: visitContext == nil ? nil : .greedy,
                    maximumResponseTokens: visitContext == nil ? nil : 1_200))
            } catch GenerateContentError.internalError(let underlying) {
                throw underlying
            }
            let modelVersion = response.rawResponse.modelVersion
            let route = InferenceRoute.reported(modelVersion: modelVersion)
            return GeneratedBrief(document: try BriefParser.parse(response.content, notes: validated), route: route)
        case .onDeviceOnly:
            if AppConfiguration.isFirebaseReady {
                let ai = FirebaseAI.firebaseAI(backend: .googleAI())
                let session = ai.generativeModelSession(model: localModel)
                let response = try await session.respond(to: prompt, options: FirebaseAI.GenerationOptions(
                    sampling: visitContext == nil ? nil : .greedy,
                    maximumResponseTokens: visitContext == nil ? nil : 1_200))
                return GeneratedBrief(document: try BriefParser.parse(response.content, notes: validated), route: .onDevice)
            }

            // Keep the prototype usable before a local Firebase configuration is installed.
            let session = FoundationModels.LanguageModelSession()
            let response = try await session.respond(to: prompt, options: FoundationModels.GenerationOptions(
                sampling: visitContext == nil ? nil : .greedy,
                maximumResponseTokens: visitContext == nil ? nil : 1_200))
            return GeneratedBrief(document: try BriefParser.parse(response.content, notes: validated), route: .onDevice)
        case .blocked:
            throw BriefProcessingError.onDeviceUnavailable
        }
    }
}
