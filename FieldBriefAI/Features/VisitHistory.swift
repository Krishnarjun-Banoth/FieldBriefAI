import Foundation
import SwiftUI

struct FieldSite: Identifiable, Codable {
    var id = UUID()
    let client: String
    let name: String

    var displayName: String { client.isEmpty ? name : "\(client) · \(name)" }
}

struct SavedVisit: Identifiable, Codable {
    var id = UUID()
    let siteID: UUID
    let date: Date
    var brief: FieldBrief
}

struct FollowUpEvent: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let completed: Bool
    let note: String?
    let visitID: UUID?
}

struct VisitFollowUp: Identifiable, Codable {
    let id: UUID
    let visitID: UUID
    var action: BriefAction
    var completedAt: Date?
    var completionNote: String?
    var completionVisitID: UUID?
    var events: [FollowUpEvent]? = nil

    // Older archives have only the latest completion; retain it on first change.
    var history: [FollowUpEvent] {
        if let events { return events }
        guard let completedAt else { return [] }
        return [FollowUpEvent(date: completedAt, completed: true,
                              note: completionNote, visitID: completionVisitID)]
    }

    func isOpen(at date: Date, visitDates: [UUID: Date]) -> Bool {
        let applicable = history.filter {
            ($0.visitID.flatMap { visitDates[$0] } ?? $0.date) <= date
        }.sorted {
            let left = $0.visitID.flatMap { visitDates[$0] } ?? $0.date
            let right = $1.visitID.flatMap { visitDates[$0] } ?? $1.date
            return left == right ? $0.date < $1.date : left < right
        }
        return !(applicable.last?.completed ?? false)
    }
}

@MainActor
final class VisitHistory: ObservableObject {
    private struct Archive: Codable {
        var sites: [FieldSite] = []
        var visits: [SavedVisit] = []
        var followUps: [VisitFollowUp] = []
    }

    @Published private var archive = Archive()
    @Published var error: String?
    private let file: URL
    private var canWrite = true

    init(storageURL: URL? = nil) {
        var filename = "fieldbrief-visits.json"
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let flag = arguments.firstIndex(of: "-visitHistoryUITest") {
            if arguments.indices.contains(flag + 1), let testID = UUID(uuidString: arguments[flag + 1]) {
                filename = "fieldbrief-test-\(testID.uuidString).json"
            } else {
                // Malformed test arguments must never open normal user history.
                filename = "fieldbrief-invalid-test-\(UUID().uuidString).json"
            }
        }
        #endif
        file = storageURL ?? URL.applicationSupportDirectory.appending(path: filename)
        do {
            archive = try JSONDecoder().decode(Archive.self, from: Data(contentsOf: file))
        } catch CocoaError.fileReadNoSuchFile {
            // No visits have been saved yet.
        } catch {
            canWrite = false
            self.error = "Saved visits could not be opened. Existing data was preserved."
        }
    }

    #if DEBUG
    func seedBackupTestHistory() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-visitHistoryUITest"), arguments.contains("-prepareRecordingSite"), sites.isEmpty {
            // Prepare only an empty fictional site. Every recorded brief uses actual inference.
            _ = addSite(client: "Northline Maintenance", name: "North Warehouse")
            return
        }
        guard arguments.contains("-visitHistoryUITest"), (arguments.contains("-seedBackupHistory") || arguments.contains("-seedComparisonHistory")),
              sites.isEmpty, let site = addSite(client: "", name: "Backup test site") else { return }
        _ = save(FieldBrief(title: "Sample restored visit", summary: "Synthetic visit.",
                            actions: [BriefAction(task: "Check the filter")]), at: site.id, updating: nil)
    }
    #endif

    var sites: [FieldSite] { archive.sites }

    func visits(at site: UUID) -> [SavedVisit] {
        archive.visits.filter { $0.siteID == site }.sorted { $0.date > $1.date }
    }

    func followUps(at site: UUID) -> [VisitFollowUp] {
        let visitIDs = Set(visits(at: site).map(\.id))
        return archive.followUps.filter { visitIDs.contains($0.visitID) }
    }

    struct ComparisonContext {
        let text: String
        let actionIDs: Set<UUID>
    }

    func comparisonContext(at site: UUID) -> ComparisonContext? {
        guard let latest = visits(at: site).first else { return nil }
        let open = Array(followUps(at: site).filter { $0.completedAt == nil }.prefix(8))
        let payload: [String: Any] = [
            "previousVisit": ["id": latest.id.uuidString,
                              "date": latest.date.ISO8601Format(),
                              "summary": String(latest.brief.summary.prefix(900))],
            "openFollowUps": open.map {
                ["followUpID": $0.id.uuidString, "task": String($0.action.task.prefix(180)),
                 "owner": String($0.action.owner.prefix(60)), "due": String($0.action.due.prefix(60))]
            }
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return ComparisonContext(text: text, actionIDs: Set(open.map(\.id)))
    }

    func addSite(client: String, name: String) -> FieldSite? {
        let site = FieldSite(client: client.trimmingCharacters(in: .whitespacesAndNewlines),
                             name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !site.name.isEmpty else { return nil }
        if let existing = sites.first(where: {
            $0.client.caseInsensitiveCompare(site.client) == .orderedSame &&
            $0.name.caseInsensitiveCompare(site.name) == .orderedSame
        }) { return existing }
        var next = archive
        next.sites.append(site)
        return commit(next) ? site : nil
    }

    func save(_ brief: FieldBrief, at site: UUID, updating visitID: UUID?) -> UUID? {
        var next = archive
        let visit: SavedVisit
        if let index = next.visits.firstIndex(where: { $0.id == visitID && $0.siteID == site }) {
            next.visits[index].brief = brief
            visit = next.visits[index]
        } else {
            visit = SavedVisit(siteID: site, date: Date(), brief: brief)
            next.visits.append(visit)
        }
        let existing = next.followUps.filter { $0.visitID == visit.id }
        next.followUps.removeAll { $0.visitID == visit.id }
        next.followUps += brief.actions.map { action in
            let prior = existing.first { $0.action.id == action.id }
            return VisitFollowUp(id: prior?.id ?? UUID(), visitID: visit.id, action: action,
                                 completedAt: prior?.completedAt, completionNote: prior?.completionNote,
                                 completionVisitID: prior?.completionVisitID, events: prior?.events)
        }
        return commit(next) ? visit.id : nil
    }

    func setCompleted(_ id: UUID, completed: Bool, note: String = "", visitID: UUID? = nil) {
        var next = archive
        guard let index = next.followUps.firstIndex(where: { $0.id == id }) else { return }
        guard (next.followUps[index].completedAt != nil) != completed else { return }
        if let visitID, completed {
            guard let origin = next.visits.first(where: { $0.id == next.followUps[index].visitID }),
                  let resolution = next.visits.first(where: { $0.id == visitID }),
                  resolution.siteID == origin.siteID, resolution.date > origin.date else { return }
        }
        let now = Date()
        var events = next.followUps[index].history
        events.append(FollowUpEvent(date: now, completed: completed,
                                   note: completed && !note.isEmpty ? note : nil,
                                   visitID: completed ? visitID : nil))
        next.followUps[index].events = events
        next.followUps[index].completedAt = completed ? now : nil
        next.followUps[index].completionNote = completed && !note.isEmpty ? note : nil
        next.followUps[index].completionVisitID = completed ? visitID : nil
        _ = commit(next)
    }

    private struct Backup: Codable {
        let format: String
        let version: Int
        let archive: Archive
    }

    struct RestorePreview {
        fileprivate let data: Data
        let siteCount: Int
        let visitCount: Int
    }

    func backupData() throws -> Data {
        guard canWrite else { throw CocoaError(.fileReadCorruptFile) }
        return try JSONEncoder().encode(Backup(format: "FieldBriefAI", version: 1, archive: archive))
    }

    func previewBackup(_ data: Data) throws -> RestorePreview {
        let backup = try validatedBackup(data)
        return RestorePreview(data: data, siteCount: backup.sites.count, visitCount: backup.visits.count)
    }

    func restore(_ preview: RestorePreview) throws -> Bool {
        let restored = try validatedBackup(preview.data)
        if !canWrite {
            // Preserve unreadable history before the user's confirmed replacement.
            // A copy failure leaves the original and write protection untouched.
            let preserved = file.appendingPathExtension("unreadable-\(UUID().uuidString)")
            try FileManager.default.copyItem(at: file, to: preserved)
        }
        guard commit(restored, recovering: true) else { return false }
        canWrite = true
        error = nil
        return true
    }

    private func validatedBackup(_ data: Data) throws -> Archive {
        let backup = try JSONDecoder().decode(Backup.self, from: data)
        let restored = backup.archive
        let siteIDs = Set(restored.sites.map(\.id))
        let visitIDs = Set(restored.visits.map(\.id))
        guard backup.format == "FieldBriefAI", backup.version == 1,
              siteIDs.count == restored.sites.count, visitIDs.count == restored.visits.count,
              Set(restored.followUps.map(\.id)).count == restored.followUps.count,
              restored.visits.allSatisfy({ siteIDs.contains($0.siteID) }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let visitsByID = Dictionary(uniqueKeysWithValues: restored.visits.map { ($0.id, $0) })
        guard restored.followUps.allSatisfy({ item in
            guard let origin = visitsByID[item.visitID],
                  origin.brief.actions.contains(where: { $0.id == item.action.id }) else { return false }
            guard Set(item.history.map(\.id)).count == item.history.count,
                  item.history.allSatisfy({ event in
                      guard let linked = event.visitID else { return true }
                      guard let visit = visitsByID[linked] else { return false }
                      return event.completed && visit.siteID == origin.siteID && visit.date > origin.date
                  }) else { return false }
            guard let resolvedID = item.completionVisitID else { return true }
            guard let resolved = visitsByID[resolvedID] else { return false }
            return item.completedAt != nil && resolved.siteID == origin.siteID && resolved.date > origin.date
        }) else { throw CocoaError(.fileReadCorruptFile) }
        return restored
    }

    private func commit(_ next: Archive, recovering: Bool = false) -> Bool {
        guard canWrite || recovering else {
            error = "Visit history is unavailable. No data was overwritten."
            return false
        }
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try JSONEncoder().encode(next).write(to: file, options: [.atomic, .completeFileProtection])
            archive = next
            return true
        } catch {
            self.error = "Changes could not be saved. Try again."
            return false
        }
    }
}
