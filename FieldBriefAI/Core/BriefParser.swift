import Foundation

public enum BriefParsingError: Error, LocalizedError, Equatable {
    case malformedResponse
    case missingRequiredContent
    case responseTooLarge

    public var errorDescription: String? {
        switch self {
        case .malformedResponse: return "AI response was not valid brief JSON. Try generating again."
        case .missingRequiredContent: return "The generated brief was incomplete. Try again."
        case .responseTooLarge: return "The AI response was unexpectedly long."
        }
    }
}

public enum BriefParser {
    private struct RawAction: Decodable {
        let task: String
        let owner: String?
        let due: String?
    }

    private struct RawResolution: Decodable {
        let followUpID: String
        let evidence: String?
        let evidenceIndex: Int?
    }

    private struct RawBrief: Decodable {
        let title: String
        let summary: String
        let decisions: [String]?
        let actions: [RawAction]?
        let risks: [String]?
        let openQuestions: [String]?
    }

    public static func parse(_ text: String, notes: String? = nil) throws -> FieldBrief {
        guard text.count <= 30_000 else { throw BriefParsingError.responseTooLarge }
        var json = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if json.hasPrefix("```") {
            guard let firstNewline = json.firstIndex(of: "\n") else {
                throw BriefParsingError.malformedResponse
            }
            json = String(json[json.index(after: firstNewline)...])
            if json.hasSuffix("```") { json.removeLast(3) }
            json = json.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let data = json.data(using: .utf8),
              var decoded = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw BriefParsingError.malformedResponse
        }
        // Never reinterpret action objects as agreed decisions. Keep only actual strings.
        for key in ["decisions", "risks", "openQuestions"] {
            if let values = decoded[key] as? [Any] { decoded[key] = values.compactMap { $0 as? String } }
        }
        guard let normalized = try? JSONSerialization.data(withJSONObject: decoded),
              let raw = try? JSONDecoder().decode(RawBrief.self, from: normalized) else {
            throw BriefParsingError.malformedResponse
        }
        let title = raw.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = raw.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty && !summary.isEmpty else {
            throw BriefParsingError.missingRequiredContent
        }
        func tidy(_ values: [String]?) -> [String] {
            (values ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        func optionalDetail(_ value: String?) -> String {
            let text = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return ["unknown", "n/a", "not specified", "unspecified", "tbd", "not assigned", "not set"]
                .contains(text.lowercased()) ? "" : text
        }
        let actions = (raw.actions ?? []).compactMap { action -> BriefAction? in
            let task = action.task.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !task.isEmpty else { return nil }
            return BriefAction(
                task: task,
                owner: optionalDetail(action.owner),
                due: optionalDetail(action.due)
            )
        }
        var brief = FieldBrief(
            title: title,
            summary: summary,
            decisions: tidy(raw.decisions),
            actions: actions,
            risks: tidy(raw.risks),
            openQuestions: tidy(raw.openQuestions)
        )
        let excerpts = notes.map(VisitComparison.excerpts) ?? []
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        brief.changesSinceLastVisit = (object?["changesSinceLastVisit"] as? [Any])?.compactMap { value in
            if let text = value as? String { return text.isEmpty ? nil : text }
            if let index = value as? Int, excerpts.indices.contains(index) { return excerpts[index] }
            return nil
        }
        let resolutions = (object?["suggestedResolutions"] as? [Any] ?? []).compactMap { value -> RawResolution? in
            guard let encoded = try? JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed]) else { return nil }
            return try? JSONDecoder().decode(RawResolution.self, from: encoded)
        }
        brief.suggestedResolutions = resolutions.compactMap { item in
            guard let actionID = UUID(uuidString: item.followUpID) else { return nil }
            if let index = item.evidenceIndex, excerpts.indices.contains(index) {
                return ResolutionSuggestion(followUpID: actionID, evidence: excerpts[index])
            }
            guard let evidence = item.evidence else { return nil }
            return ResolutionSuggestion(followUpID: actionID, evidence: evidence)
        }
        return brief
    }
}


public enum VisitComparison {
    public static func excerpts(_ notes: String) -> [String] {
        notes.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    /// Reject invented IDs, duplicate proposals and evidence not present in the current notes.
    public static func validated(_ suggestions: [ResolutionSuggestion], notes: String,
                                 allowedIDs: Set<UUID>, tasks: [UUID: String] = [:]) -> [ResolutionSuggestion] {
        var seen = Set<UUID>()
        return suggestions.filter {
            let quote = $0.evidence.trimmingCharacters(in: .whitespacesAndNewlines)
            return allowedIDs.contains($0.followUpID) && !quote.isEmpty &&
                quote.count >= 12 && notes.contains(quote) &&
                (tasks[$0.followUpID].map { explicitCompletion(quote: quote, notes: notes, task: $0) } ?? true) &&
                seen.insert($0.followUpID).inserted
        }
    }
    /// Merge model proposals with conservative literal matches; these are review candidates only.
    public static func candidates(_ suggestions: [ResolutionSuggestion], notes: String,
                                  tasks: [UUID: String]) -> [ResolutionSuggestion] {
        var proposals = validated(suggestions, notes: notes, allowedIDs: Set(tasks.keys), tasks: tasks)
        let seen = Set(proposals.map(\.followUpID))
        for id in tasks.keys.sorted(by: { $0.uuidString < $1.uuidString }) where !seen.contains(id) {
            if let task = tasks[id], let excerpt = excerpts(notes).first(where: {
                $0.count >= 12 && explicitCompletion(quote: $0, notes: notes, task: task)
            }) { proposals.append(ResolutionSuggestion(followUpID: id, evidence: excerpt)) }
        }
        return proposals
    }

    /// Conservative English guard: uncertain or conflicting notes remain manual work.
    /// This deliberately trades recall for fewer unsafe completion suggestions.
    public static func explicitCompletion(quote: String, notes: String, task: String) -> Bool {
        func matches(_ pattern: String, _ text: String) -> Bool {
            text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
        guard !matches(#"\b(will|would|could|should|might|may|not|never|waiting|unclear|unconfirmed|pending|planned|tomorrow|needs|still)\b|n['’]t\b|\bnext (week|month|friday|visit)\b|\b(other|different) site\b|close all actions"#, notes),
              matches(#"\b(replaced|repaired|checked|inspected|delivered|submitted|sent|resolved|installed|fixed|completed|finished|done)\b"#, quote) else { return false }
        let ignored: Set<String> = ["the", "a", "an", "to", "of", "for", "and", "by", "with", "check", "inspect", "replace", "repair", "send", "complete", "fix", "review"]
        // Scheduling language is not part of the repaired object's identity. Strip only
        // this explicit trailing deadline; keep substantive prerequisites in the match.
        let action = task.replacingOccurrences(
            of: #"\s+(?:before|by)\s+(?:the\s+)?next\s+visit[.!]?$"#,
            with: "", options: [.regularExpression, .caseInsensitive])
        let words = action.lowercased().components(separatedBy: CharacterSet.letters.inverted)
            .filter { $0.count > 2 && !ignored.contains($0) }
        return !words.isEmpty && words.allSatisfy { word in
            matches("\\b" + NSRegularExpression.escapedPattern(for: word) + "\\b", quote)
        }
    }

}
