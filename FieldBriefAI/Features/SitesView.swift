import SwiftUI
import UniformTypeIdentifiers

struct SitesView: View {
    @ObservedObject var history: VisitHistory
    @Binding var selection: UUID?
    @Environment(\.dismiss) private var dismiss
    @State private var backup: HistoryBackupDocument?
    @State private var exporting = false
    @State private var importing = false
    @State private var restorePreview: VisitHistory.RestorePreview?
    @State private var showRestore = false
    @State private var message: String?
    @State private var search = ""
    @State private var client = ""
    @State private var name = ""
    @State private var completion: VisitFollowUp?
    @State private var completionNote = ""
    @State private var completionVisitID: UUID?

    private var backupDefaultFilename: String {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-backupFilename"),
           arguments.indices.contains(index + 1) {
            return arguments[index + 1]
        }
        #endif
        return "FieldBrief-Backup"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Export backup") {
                        do {
                            backup = HistoryBackupDocument(data: try history.backupData())
                            exporting = true
                        } catch { message = "The backup could not be prepared." }
                    }
                    Button("Restore from backup") { importing = true }
                } header: {
                    Text("Backup and restore")
                } footer: {
                    Text("A backup includes saved client information and visit notes. Store it somewhere private.")
                }
                Section("Saved sites") {
                    ForEach(history.sites.filter {
                        search.isEmpty || $0.displayName.localizedCaseInsensitiveContains(search)
                    }) { site in
                        NavigationLink {
                            siteDetail(site)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(site.displayName)
                                let visitCount = history.visits(at: site.id).count
                                let openCount = history.followUps(at: site.id).filter { $0.completedAt == nil }.count
                                Text("\(visitCount) visits · \(openCount) open follow-ups")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityIdentifier("savedSite-\(site.displayName)")
                    }
                    if history.sites.isEmpty {
                        Text("Add a site to save briefs and track follow-ups across visits.")
                            .foregroundStyle(.secondary)
                    }
                }
                if !history.sites.isEmpty && !search.isEmpty &&
                    !history.sites.contains(where: { $0.displayName.localizedCaseInsensitiveContains(search) }) {
                    Text("No matching sites. Try a different site or client name.")
                        .foregroundStyle(.secondary)
                }
                Section("Add site") {
                    TextField("Client or organization (optional)", text: $client)
                    TextField("Site name", text: $name)
                    Button {
                        guard let site = history.addSite(client: client, name: name) else {
                            message = history.error ?? "The site could not be saved. Check available device storage and try again."
                            return
                        }
                        select(site)
                    } label: {
                        Text("Add and select site")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("addAndSelectSite")
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .fileExporter(isPresented: $exporting, document: backup, contentType: .json,
                          defaultFilename: backupDefaultFilename) { result in
                if case .failure = result { message = "The backup could not be exported." }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                do {
                    let url = try result.get()
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    restorePreview = try history.previewBackup(Data(contentsOf: url))
                    showRestore = true
                } catch { message = "This file could not be opened as a FieldBrief backup." }
            }
            .alert("Replace visit history?", isPresented: $showRestore, presenting: restorePreview) { preview in
                Button("Cancel", role: .cancel) { restorePreview = nil }
                Button("Replace history", role: .destructive) {
                    defer { restorePreview = nil }
                    do {
                        if try history.restore(preview) {
                            selection = nil
                            message = "Visit history restored."
                        } else { message = "The restore could not be saved." }
                    } catch { message = "The backup could not be restored." }
                }
            } message: { preview in
                Text("Restore \(preview.siteCount) sites and \(preview.visitCount) visits? This replaces the history on this iPhone. Export the current history first if you need to keep it.")
            }
            .alert("Visit history", isPresented: Binding(
                get: { message != nil }, set: { if !$0 { message = nil } }
            )) {
                Button("OK") { message = nil }
            } message: {
                Text(message ?? "")
            }
            .searchable(text: $search, prompt: "Search sites")
            .navigationTitle("Sites")
            .toolbar { Button("Done") { dismiss() } }
        }
    }

    private func siteDetail(_ site: FieldSite) -> some View {
        let visits = history.visits(at: site.id)
        let followUps = history.followUps(at: site.id)
        return List {
            Button("Use this site") { select(site) }
            Section("Open follow-ups") {
                let open = followUps.filter { $0.completedAt == nil }
                if open.isEmpty { Text("No open follow-ups").foregroundStyle(.secondary) }
                ForEach(open) { followUp in
                    VStack(alignment: .leading) {
                        Text(followUp.action.task)
                        if !followUp.action.owner.isEmpty { Text(followUp.action.owner).foregroundStyle(.secondary) }
                        if !followUp.action.due.isEmpty { Text("Due: \(followUp.action.due)").foregroundStyle(.secondary) }
                        if !followUp.history.isEmpty {
                            DisclosureGroup("Follow-up history") {
                                ForEach(followUp.history) { event in
                                    VStack(alignment: .leading) {
                                        Text(event.completed ? "Completed" : "Reopened")
                                        Text(event.date, format: .dateTime.day().month().year().hour().minute())
                                            .font(.caption)
                                        if let note = event.note { Text(note) }
                                    }
                                }
                            }
                        }
                        Button("Mark complete") {
                            completionNote = ""
                            completionVisitID = nil
                            completion = followUp
                        }
                    }
                }
            }
            if followUps.contains(where: { $0.completedAt != nil }) {
                Section("Completed follow-ups") {
                    ForEach(followUps.filter { $0.completedAt != nil }) { followUp in
                        VStack(alignment: .leading) {
                            Text(followUp.action.task)
                            if let note = followUp.completionNote { Text(note).foregroundStyle(.secondary) }
                            if let visit = visits.first(where: { $0.id == followUp.completionVisitID }) {
                                Text("Resolved during \(visit.date.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Button("Reopen") { history.setCompleted(followUp.id, completed: false) }
                        }
                    }
                }
            }
            Section("Visit history") {
                if visits.isEmpty { Text("No saved visits yet").foregroundStyle(.secondary) }
                ForEach(visits) { visit in
                    NavigationLink {
                        let resolutions = followUps.flatMap { item in
                            item.history.filter { $0.completed && $0.visitID == visit.id }.map { event in
                                "- \(item.action.task)" + (event.note.map { ": \($0)" } ?? "")
                            }
                        }
                        let resolutionText = resolutions.isEmpty ? "" : "\n## Follow-ups completed during this visit\n" +
                            resolutions.joined(separator: "\n")
                        let report = "\(site.displayName)\n\(visit.date.formatted(date: .abbreviated, time: .shortened))\n\n\(visit.brief.markdown)\(resolutionText)"
                        let dates = Dictionary(uniqueKeysWithValues: visits.map { ($0.id, $0.date) })
                        let open = followUps.filter { item in
                            guard let raised = dates[item.visitID], raised <= visit.date else { return false }
                            return item.isOpen(at: visit.date, visitDates: dates)
                        }
                        let openText = open.map { item in
                            let owner = item.action.owner.isEmpty ? "Unassigned" : item.action.owner
                            let due = item.action.due.isEmpty ? "No due date" : item.action.due
                            return "- \(item.action.task) · \(owner) · \(due)"
                        }.joined(separator: "\n")
                        VisitReportView(title: visit.brief.title, report: report +
                            "\n\n## Open follow-ups at this visit\n" + (openText.isEmpty ? "None" : openText))

                    } label: {
                        VStack(alignment: .leading) {
                            Text(visit.brief.title)
                            Text(visit.date, format: .dateTime.day().month().year())
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("savedVisitRow")
                }
            }
        }
        .navigationTitle(site.name)
        .sheet(item: $completion) { followUp in
            NavigationStack {
                Form {
                    Text(followUp.action.task)
                    TextField("Completion note (optional)", text: $completionNote, axis: .vertical)
                        .accessibilityIdentifier("completionNote")
                    Section("Resolved during visit") {
                        Button {
                            completionVisitID = nil
                        } label: {
                            selectionLabel("No linked visit", selected: completionVisitID == nil)
                        }
                        ForEach(visits.filter { candidate in
                            guard let original = visits.first(where: { $0.id == followUp.visitID })
                            else { return false }
                            return candidate.date > original.date
                        }) { visit in
                            Button {
                                completionVisitID = visit.id
                            } label: {
                                selectionLabel("\(visit.brief.title) · \(visit.date.formatted(date: .abbreviated, time: .shortened))",
                                               selected: completionVisitID == visit.id)
                            }
                            .accessibilityIdentifier("completionVisitOption")
                        }
                    }
                }
                .navigationTitle("Complete follow-up")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { completion = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save completion") {
                            let note = completionNote.trimmingCharacters(in: .whitespacesAndNewlines)
                            let visitID = completionVisitID
                            completion = nil
                            history.setCompleted(followUp.id, completed: true,
                                                 note: note, visitID: visitID)
                        }
                    }
                }
            }
        }
    }

    private func selectionLabel(_ title: String, selected: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            if selected { Image(systemName: "checkmark").accessibilityHidden(true) }
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func select(_ site: FieldSite) {
        selection = site.id
        dismiss()
    }
}


private struct HistoryBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        data = contents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
