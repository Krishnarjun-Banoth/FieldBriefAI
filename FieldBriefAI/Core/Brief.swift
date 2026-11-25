import Foundation

public struct BriefAction: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var task: String
    public var owner: String
    public var due: String

    public init(id: UUID = UUID(), task: String, owner: String = "", due: String = "") {
        self.id = id
        self.task = task
        self.owner = owner
        self.due = due
    }
}

public struct ResolutionSuggestion: Equatable, Codable, Sendable, Identifiable {
    public var followUpID: UUID
    public var evidence: String
    public var id: UUID { followUpID }
}

public struct FieldBrief: Equatable, Codable, Sendable {
    public var title: String
    public var summary: String
    public var decisions: [String]
    public var actions: [BriefAction]
    public var risks: [String]
    public var openQuestions: [String]
    public var changesSinceLastVisit: [String]? = nil
    public var suggestedResolutions: [ResolutionSuggestion]? = nil

    public init(
        title: String,
        summary: String,
        decisions: [String] = [],
        actions: [BriefAction] = [],
        risks: [String] = [],
        openQuestions: [String] = []
    ) {
        self.title = title
        self.summary = summary
        self.decisions = decisions
        self.actions = actions
        self.risks = risks
        self.openQuestions = openQuestions
    }

    public var markdown: String {
        var output = "# \(title)\n\n\(summary)\n"
        if !decisions.isEmpty {
            output += "\n## Decisions\n" + decisions.map { "- \($0)" }.joined(separator: "\n") + "\n"
        }
        if !actions.isEmpty {
            output += "\n## Next actions\n" + actions.map { action in
                let owner = action.owner.isEmpty ? "" : " · Person responsible: \(action.owner)"
                let due = action.due.isEmpty ? "" : " · Due: \(action.due)"
                return "- [ ] \(action.task)\(owner)\(due)"
            }.joined(separator: "\n") + "\n"
        }
        if !risks.isEmpty {
            output += "\n## Risks\n" + risks.map { "- \($0)" }.joined(separator: "\n") + "\n"
        }
        if !openQuestions.isEmpty {
            output += "\n## To confirm\n" + openQuestions.map { "- \($0)" }.joined(separator: "\n") + "\n"
        }
        if let changes = changesSinceLastVisit, !changes.isEmpty {
            output += "\n## AI comparison with previous visit — review required\n" +
                changes.map { "- \($0)" }.joined(separator: "\n") + "\n"
        }
        return output
    }
}
