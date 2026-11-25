import Foundation

@main
struct HistoryRecoveryCheck {
    @MainActor static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = VisitHistory(storageURL: root.appendingPathComponent("source.json"))
        let site = source.addSite(client: "Synthetic client", name: "Test site")!
        _ = source.save(FieldBrief(title: "Test visit", summary: "Synthetic notes", actions: [BriefAction(task: "Inspect filter")]), at: site.id, updating: nil)
        let secondID = source.save(FieldBrief(title: "Second visit", summary: "Filter replaced"), at: site.id, updating: nil)!
        let followUpID = source.followUps(at: site.id)[0].id
        source.setCompleted(followUpID, completed: true, note: "Filter replaced", visitID: secondID)
        let secondDate = source.visits(at: site.id).first { $0.id == secondID }!.date
        let dates = Dictionary(uniqueKeysWithValues: source.visits(at: site.id).map { ($0.id, $0.date) })
        source.setCompleted(followUpID, completed: false)
        let reopenedAction = source.followUps(at: site.id)[0]
        precondition(reopenedAction.completedAt == nil)
        precondition(reopenedAction.history.count == 2)
        precondition(reopenedAction.history[0].note == "Filter replaced")
        precondition(reopenedAction.history[0].visitID == secondID)
        precondition(!reopenedAction.isOpen(at: secondDate, visitDates: dates))
        precondition(reopenedAction.isOpen(at: Date(), visitDates: dates))
        let backup = try source.backupData()
        // A backup must reject broken relationships without mutating live history.
        let baseline = try JSONSerialization.jsonObject(with: backup) as! [String: Any]
        func reject(_ mutate: (inout [String: Any]) -> Void) throws {
            var candidate = baseline
            mutate(&candidate)
            let before = try source.backupData()
            do {
                _ = try source.previewBackup(JSONSerialization.data(withJSONObject: candidate))
                fatalError("Damaged backup accepted")
            } catch {}
            let after = try source.backupData()
            let beforeObject = try JSONSerialization.jsonObject(with: before) as! NSDictionary
            let afterObject = try JSONSerialization.jsonObject(with: after) as! NSDictionary
            precondition(beforeObject == afterObject)
        }
        try reject { $0["version"] = 999 }
        try reject { value in
            var a = value["archive"] as! [String: Any]
            var sites = a["sites"] as! [[String: Any]]
            sites.append(sites[0]); a["sites"] = sites; value["archive"] = a
        }
        try reject { value in
            var a = value["archive"] as! [String: Any]
            a["sites"] = []; value["archive"] = a
        }
        try reject { value in
            var a = value["archive"] as! [String: Any]
            var items = a["followUps"] as! [[String: Any]]
            items[0]["visitID"] = UUID().uuidString
            a["followUps"] = items; value["archive"] = a
        }
        // Completing an action at a different site must leave it open.
        let other = source.addSite(client: "Synthetic client", name: "Other site")!
        let otherVisit = source.save(FieldBrief(title: "Other visit", summary: "Unrelated"),
                                     at: other.id, updating: nil)!
        source.setCompleted(followUpID, completed: true, note: "Wrong site", visitID: otherVisit)
        precondition(source.followUps(at: site.id)[0].completedAt == nil)
        precondition(source.followUps(at: other.id).isEmpty)
        precondition(source.visits(at: site.id).count == 2)
        let target = root.appendingPathComponent("target.json")
        let broken = Data("corrupt history".utf8)
        try broken.write(to: target)
        let recovery = VisitHistory(storageURL: target)
        precondition(recovery.addSite(client: "", name: "Must not overwrite") == nil)
        do { _ = try recovery.previewBackup(Data("{}".utf8)); fatalError("Invalid backup accepted") } catch {}
        let originalBytes = try Data(contentsOf: target)
        precondition(originalBytes == broken)
        let preview = try recovery.previewBackup(backup)
        let restored = try recovery.restore(preview)
        guard restored else { print("FAIL: valid backup cannot recover corrupt history"); exit(1) }
        precondition(recovery.error == nil)
        let reopened = VisitHistory(storageURL: target)
        precondition(reopened.sites.count == 1)
        precondition(reopened.visits(at: site.id).count == 2)
        precondition(reopened.followUps(at: site.id).count == 1)
        precondition(reopened.followUps(at: site.id)[0].history.count == 2)
        precondition(reopened.followUps(at: site.id)[0].history[0].note == "Filter replaced")
        // Legacy completion records without events still migrate when reopened.
        var legacy = try JSONSerialization.jsonObject(with: backup) as! [String: Any]
        var archive = legacy["archive"] as! [String: Any]
        var items = archive["followUps"] as! [[String: Any]]
        items[0].removeValue(forKey: "events")
        items[0]["completedAt"] = Date().timeIntervalSinceReferenceDate
        items[0]["completionNote"] = "Legacy resolution"
        items[0]["completionVisitID"] = secondID.uuidString
        archive["followUps"] = items
        legacy["archive"] = archive
        let legacyStore = VisitHistory(storageURL: root.appendingPathComponent("legacy.json"))
        let legacyPreview = try legacyStore.previewBackup(JSONSerialization.data(withJSONObject: legacy))
        let legacyRestored = try legacyStore.restore(legacyPreview)
        precondition(legacyRestored)
        legacyStore.setCompleted(followUpID, completed: false)
        precondition(legacyStore.followUps(at: site.id)[0].history[0].note == "Legacy resolution")
        precondition(legacyStore.followUps(at: site.id)[0].history.count == 2)
        precondition(reopened.addSite(client: "", name: "After recovery") != nil)
        let preserved = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil).filter { $0.lastPathComponent.hasPrefix("target.json.unreadable-") }
        precondition(preserved.count == 1)
        let preservedBytes = try Data(contentsOf: preserved[0])
        precondition(preservedBytes == broken)
        print("PASS: corrupt history preserved; valid backup restored and writable after relaunch; invalid backup rejected")
    }
}
