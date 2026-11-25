import Foundation
import Combine

@MainActor
final class BriefViewModel: ObservableObject {
    @Published var notes = DemoNotes.sample
    @Published var brief: FieldBrief?
    @Published var route: InferenceRoute?
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var allowCloudFallback = false

    @Published private(set) var localAvailable = false
    @Published private(set) var localStatus = ""

    private let processor: any BriefAIProcessing

    init(processor: (any BriefAIProcessing)? = nil) {
        self.processor = processor ?? FirebaseHybridNoteService()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-realVisitComparison") ||
            (ProcessInfo.processInfo.arguments.contains("-visitHistoryUITest") &&
             ProcessInfo.processInfo.arguments.contains("-seedComparisonHistory")) {
            notes = ProcessInfo.processInfo.environment["FIELDBRIEF_COMPARISON_TEST_NOTES"] ?? "The filter was replaced today."
        }
        #endif
        refreshLocalAvailability()
    }

    func refreshLocalAvailability() {
        let available = processor.onDeviceAvailable
        let status = processor.onDeviceStatus
        if available != localAvailable { localAvailable = available }
        if status != localStatus { localStatus = status }
    }

    var canGenerate: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-visitHistoryUITest") { return true }
        #endif
        return !isGenerating && (!allowCloudFallback || AppConfiguration.isFirebaseReady) &&
        ((try? PromptBuilder.validatedNote(notes)) != nil) &&
        (InferencePolicy.mode(localAvailable: localAvailable, cloudConsented: allowCloudFallback) != .blocked)
    }

    func generate(visitContext: String? = nil) {
        guard !isGenerating else { return }
        do { _ = try PromptBuilder.validatedNote(notes) }
        catch {
            errorMessage = error.localizedDescription
            return
        }
        guard !allowCloudFallback || AppConfiguration.isFirebaseReady else {
            errorMessage = BriefProcessingError.missingFirebaseConfiguration.localizedDescription
            return
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-visitHistoryUITest") &&
            !ProcessInfo.processInfo.arguments.contains("-realVisitComparison") {
            errorMessage = nil
            brief = FieldBrief(title: "Service visit", summary: "Synthetic visit report.",
                               actions: [BriefAction(task: "Check the service log", owner: "Priya")])
            if let visitContext, let data = visitContext.data(using: .utf8),
               let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let actions = object["openFollowUps"] as? [[String: String]],
               let value = actions.first?["followUpID"], let id = UUID(uuidString: value) {
                brief?.changesSinceLastVisit = ["The filter has been replaced."]
                brief?.suggestedResolutions = [ResolutionSuggestion(followUpID: id,
                    evidence: "The filter was replaced today.")]
            }
            route = .onDevice
            return
        }
        #endif
        refreshLocalAvailability()
        guard localAvailable || allowCloudFallback else {
            errorMessage = BriefProcessingError.onDeviceUnavailable.localizedDescription
            return
        }
        isGenerating = true
        errorMessage = nil
        brief = nil
        route = nil
        let currentNotes = notes
        let fallbackPermission = allowCloudFallback
        Task {
            defer { isGenerating = false }
            do {
                let result = try await processor.generate(note: currentNotes, allowCloud: fallbackPermission, visitContext: visitContext)
                brief = result.document
                route = result.route
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

enum DemoNotes {
    static let sample = """
    Met the operations team about an iOS onboarding pilot. They want to test with 20 volunteers before rollout. Priya will send a list of supported devices by Friday. A decision was made to begin with English only. The team is concerned about offline access and has not chosen a launch date. Need to confirm who approves the final pilot and whether devices have Apple Intelligence enabled.
    """
}
