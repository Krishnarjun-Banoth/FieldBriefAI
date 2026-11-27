import SwiftUI
import UIKit

private enum FieldBriefTheme {
    static let buttonFill = Color(red: 0.08, green: 0.32, blue: 0.24)
    static let pine = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.40, green: 0.83, blue: 0.66, alpha: 1)
            : UIColor(red: 0.08, green: 0.32, blue: 0.24, alpha: 1)
    })
    static let mint = Color(red: 0.88, green: 0.96, blue: 0.92)
}

struct ContentView: View {
    fileprivate enum EditingField: Hashable {
        case notes, title, summary
        case action(UUID), owner(UUID), due(UUID)
    }

    @FocusState private var editingField: EditingField?
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = BriefViewModel()
    @StateObject private var history = VisitHistory()
    @State private var selectedSiteID: UUID?
    @State private var showSites = false
    @State private var savedVisitID: UUID?
    @State private var showCloudConsent = false
    @State private var compareHistory = false
    @State private var comparisonSiteID: UUID?
    @State private var comparisonNotes = ""
    @State private var comparisonIDs = Set<UUID>()
    @State private var pendingResolution: ResolutionSuggestion?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    connectionStatus
                    Button {
                        showSites = true
                    } label: {
                        Label(selectedSite?.displayName ?? "Choose a site", systemImage: "building.2")
                    }
                    .accessibilityIdentifier("sitePicker")
                    .disabled(model.isGenerating)
                    comparisonControl
                    noteEntry
                    privacyControls
                    generateButton

                    if model.isGenerating {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Turning your notes into a useful brief…")
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("generatingProgress")
                    }

                    if let error = model.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .accessibilityIdentifier("generationError")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    }

                    if comparisonSiteID == selectedSiteID && comparisonNotes == model.notes {
                        comparisonReview
                    }
                    if let currentBrief = model.brief {
                        BriefResultView(
                            brief: Binding(
                                get: { model.brief ?? currentBrief },
                                set: { model.brief = $0 }
                            ),
                            route: model.route,
                            editingField: $editingField
                        )
                    }
                    if let brief = model.brief {
                        Button(savedVisitID == nil ? "Save visit" : "Update saved visit") {
                            guard let site = selectedSite else {
                                showSites = true
                                return
                            }
                            savedVisitID = history.save(brief, at: site.id, updating: savedVisitID)
                            editingField = nil
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    footer
                }
                .frame(maxWidth: 680)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 34)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(KeyboardDismissArea())
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { editingField = nil }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
        }
        #if DEBUG
        .task { history.seedBackupTestHistory() }
        #endif
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            model.refreshLocalAvailability()
            while !model.localAvailable {
                do { try await Task.sleep(for: .seconds(3)) }
                catch { return }
                model.refreshLocalAvailability()
            }
        }
        .sheet(isPresented: $showSites) {
            SitesView(history: history, selection: $selectedSiteID)
        }
        .onChange(of: selectedSiteID) { _, _ in
            savedVisitID = nil
            compareHistory = false
            comparisonSiteID = nil
            model.brief = nil
        }
        .confirmationDialog("Confirm follow-up completed?", isPresented: Binding(
            get: { pendingResolution != nil }, set: { if !$0 { pendingResolution = nil } }
        ), titleVisibility: .visible) {
            Button("Confirm completed") {
                if let suggestion = pendingResolution, let visitID = savedVisitID,
                   comparisonSiteID == selectedSiteID, comparisonNotes == model.notes {
                    history.setCompleted(suggestion.followUpID, completed: true,
                                         note: suggestion.evidence, visitID: visitID)
                }
                pendingResolution = nil
            }
            Button("Cancel", role: .cancel) { pendingResolution = nil }
        } message: {
            Text("This records your confirmation and the quoted evidence against this saved visit.")
        }
        .alert("Visit history", isPresented: Binding(
            get: { history.error != nil },
            set: { if !$0 { history.error = nil } }
        )) {
            Button("OK") { history.error = nil }
        } message: {
            Text(history.error ?? "")
        }
        .tint(FieldBriefTheme.pine)
        .alert("Allow Gemini cloud fallback?", isPresented: $showCloudConsent) {
            Button("Keep local only", role: .cancel) {
                model.allowCloudFallback = false
            }
            Button("Allow cloud fallback") {
                model.allowCloudFallback = true
            }
        } message: {
            Text("When the on-device model cannot handle your request, Firebase AI Logic may send your note and, if comparison is enabled, the selected site's previous summary and up to eight open follow-ups to Google's cloud Gemini model. Only use sanitized notes without private client details. You can turn this off at any time.")
        }
    }

    private var selectedSite: FieldSite? {
        history.sites.first { $0.id == selectedSiteID }
    }

    @ViewBuilder
    private var comparisonControl: some View {
        if let site = selectedSite, !history.visits(at: site.id).isEmpty {
            Toggle(isOn: $compareHistory) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Compare with last visit", systemImage: "clock.arrow.circlepath")
                        .font(.subheadline.weight(.semibold))
                    Text("Use the previous summary and up to 8 open follow-ups. You confirm every completion.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .accessibilityLabel("Compare with last visit")
            .accessibilityIdentifier("compareVisitToggle")
            .disabled(model.isGenerating)
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        }
    }

    @ViewBuilder
    private var comparisonReview: some View {
        if let brief = model.brief, let siteID = comparisonSiteID {
            let open = history.followUps(at: siteID).filter { $0.completedAt == nil }
            let suggestions = VisitComparison.candidates(brief.suggestedResolutions ?? [],
                notes: comparisonNotes,
                tasks: Dictionary(uniqueKeysWithValues: open.filter { comparisonIDs.contains($0.id) }
                    .map { ($0.id, $0.action.task) }))
            VStack(alignment: .leading, spacing: 12) {
                Label("Since your last visit", systemImage: "clock.arrow.circlepath").font(.headline)
                Text("AI comparison + literal task matches · Review every suggestion")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(Array((brief.changesSinceLastVisit ?? []).enumerated()), id: \.offset) { _, change in
                    Text(change).font(.subheadline)
                }
                if suggestions.isEmpty {
                    Text("No supported completion suggestions. Existing follow-ups stay open unless you confirm them in Sites.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                ForEach(suggestions) { suggestion in
                    if let item = open.first(where: { $0.id == suggestion.followUpID }) {
                        Divider()
                        Text(item.action.task).font(.subheadline.weight(.semibold))
                        Text("From this visit: “\(suggestion.evidence)”").font(.subheadline)
                        if savedVisitID == nil {
                            Text("Save this visit below to review completion.")
                                .font(.caption).foregroundStyle(.secondary)
                        } else {
                            Button("Review completion") { pendingResolution = suggestion }
                                .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))

        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 9) {
                Image(systemName: "square.text.square.fill")
                    .font(.system(size: 29, weight: .semibold))
                    .foregroundStyle(FieldBriefTheme.pine)
                Text("CHIMJA LABS")
                    .font(.caption.weight(.bold))
                    .tracking(2.1)
                    .foregroundStyle(FieldBriefTheme.pine)
            }
            Text("FieldBrief AI")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
            Text("From messy notes to clear next steps.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Keep every site visit clear, connected, and ready to share.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var connectionStatus: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: AppConfiguration.isFirebaseReady ? "checkmark.shield.fill" : "wrench.and.screwdriver.fill")
                .foregroundStyle(AppConfiguration.isFirebaseReady ? FieldBriefTheme.pine : .orange)
            VStack(alignment: .leading, spacing: 3) {
                Text(AppConfiguration.isFirebaseReady ? "Cloud configuration added" : "Cloud setup needed")
                    .font(.subheadline.weight(.semibold))
                Text(AppConfiguration.isFirebaseReady
                     ? "Ready to use Firebase AI Logic once App Check is configured."
                     : "Firebase setup and App Check are required for Gemini cloud fallback.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var noteEntry: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Your field notes", systemImage: "square.and.pencil")
                    .font(.headline)
                Spacer()
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-showSampleNotes") {
                    Button("Demo notes") { model.notes = DemoNotes.sample }
                        .font(.caption.weight(.semibold))
                }
                #endif
            }
            TextEditor(text: $model.notes)
                .focused($editingField, equals: .notes)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 160)
                .padding(12)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                .accessibilityLabel("Field notes")
                .accessibilityIdentifier("noteEditor")
                .disabled(model.isGenerating)
            HStack {
                Text("Only include information you’re authorized to process.")
                Spacer(minLength: 8)
                Text("\(model.notes.count)/\(PromptBuilder.maxNoteCharacters)")
                    .monospacedDigit()
            }
            .font(.caption2)
            .foregroundStyle(model.notes.count > PromptBuilder.maxNoteCharacters ? .red : .secondary)
        }
    }

    private var privacyControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Inference & privacy", systemImage: "lock.shield")
                .font(.headline)
            HStack(spacing: 10) {
                Image(systemName: model.localAvailable ? "iphone.gen3" : "iphone.slash")
                    .foregroundStyle(model.localAvailable ? FieldBriefTheme.pine : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.localAvailable ? "On-device model ready" : "On-device model unavailable")
                        .font(.subheadline.weight(.medium))
                    Text(model.localStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Divider()
            Toggle(isOn: Binding(
                get: { model.allowCloudFallback },
                set: { newValue in
                    if newValue { showCloudConsent = true }
                    else { model.allowCloudFallback = false }
                }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Allow cloud fallback")
                        .font(.subheadline.weight(.semibold))
                    Text("Off by default. Requires explicit permission to use Gemini if needed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("cloudFallbackToggle")
            .disabled(model.isGenerating)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private var generateButton: some View {
        Button {
            editingField = nil
            savedVisitID = nil
            let context = compareHistory ? selectedSiteID.flatMap { history.comparisonContext(at: $0) } : nil
            comparisonSiteID = context == nil ? nil : selectedSiteID
            comparisonNotes = model.notes
            comparisonIDs = context?.actionIDs ?? []
            model.generate(visitContext: context?.text)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                Text(model.isGenerating ? "Generating…" : "Create field brief")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(model.canGenerate ? FieldBriefTheme.buttonFill : Color.gray, in: RoundedRectangle(cornerRadius: 16))
        .disabled(!model.canGenerate)
        .accessibilityIdentifier("generateButton")
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("AI can misunderstand notes. Review the output before sending or relying on it.")
            Text("FieldBrief AI • Saved visits stay on this device")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
}

private struct BriefResultView: View {
    @Binding var brief: FieldBrief
    let route: InferenceRoute?
    let editingField: FocusState<ContentView.EditingField?>.Binding
    @State private var copied = false
    @State private var editingSummary = false
    @State private var summaryDraft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Your editable brief", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(FieldBriefTheme.pine)
                Spacer()
            }
            if let route {
                Label(route.displayName, systemImage: routeIcon(route))
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(FieldBriefTheme.mint, in: Capsule())
                    .foregroundStyle(Color(red: 0.08, green: 0.32, blue: 0.24))
                    .accessibilityIdentifier("inferenceRoute")
            }
            VStack(alignment: .leading, spacing: 5) {
                fieldLabel("Title")
                TextField("Brief title", text: $brief.title)
                    .focused(editingField, equals: .title)
                    .font(.title3.weight(.semibold))
                    .textInputAutocapitalization(.sentences)
                    .accessibilityIdentifier("briefTitle")
            }
            VStack(alignment: .leading, spacing: 5) {
                fieldLabel("Summary")
                Text(brief.summary)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityIdentifier("briefSummary")
                Button {
                    summaryDraft = brief.summary
                    editingSummary = true
                } label: {
                    Label("Edit summary", systemImage: "square.and.pencil")
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
                .accessibilityIdentifier("editBriefSummary")
            }
            simpleList("Decisions", items: brief.decisions, icon: "checkmark.circle")
            if !brief.actions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Next actions", systemImage: "checklist")
                        .font(.subheadline.weight(.bold))
                    Text("Add a person and due date where the notes leave them unspecified.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach($brief.actions) { $action in
                        VStack(alignment: .leading, spacing: 7) {
                            TextField("Action", text: $action.task, axis: .vertical)
                                .focused(editingField, equals: .action(action.id))
                                .font(.subheadline.weight(.medium))
                                .accessibilityIdentifier("briefActionTask-\(action.id.uuidString)")
                            VStack(alignment: .leading, spacing: 10) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Person responsible").font(.caption.weight(.semibold))
                                    TextField("Not assigned — add a name", text: $action.owner)
                                        .focused(editingField, equals: .owner(action.id))
                                        .accessibilityLabel("Person responsible")
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Due date").font(.caption.weight(.semibold))
                                    TextField("Not set — e.g. Friday", text: $action.due)
                                        .focused(editingField, equals: .due(action.id))
                                        .accessibilityLabel("Due date")
                                }
                            }
                            .font(.caption)
                            .textFieldStyle(.roundedBorder)
                            Button(role: .destructive) {
                                let actionID = action.id
                                brief.actions.removeAll { $0.id == actionID }
                            } label: {
                                Label("Remove action", systemImage: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityIdentifier("removeBriefAction-\(action.id.uuidString)")
                        }
                        .padding(11)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            simpleList("Risks", items: brief.risks, icon: "exclamationmark.triangle")
            simpleList("To confirm", items: brief.openQuestions, icon: "questionmark.circle")
            HStack(spacing: 10) {
                Button {
                    UIPasteboard.general.string = brief.markdown
                    copied = true
                } label: {
                    Label(copied ? "Copied" : "Copy brief", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(FieldBriefTheme.buttonFill)
                .foregroundStyle(.white)
                ShareLink(item: brief.markdown) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .onChange(of: brief) { copied = false }
        .sheet(isPresented: $editingSummary) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Check the draft against your field notes before saving.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    TextEditor(text: $summaryDraft)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                        .accessibilityLabel("Summary draft")
                        .accessibilityIdentifier("summaryDraft")
                }
                .padding(20)
                .navigationTitle("Edit summary")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { editingSummary = false }
                    }
                    ToolbarItemGroup(placement: .confirmationAction) {
                        Button("Clear", role: .destructive) { summaryDraft = "" }
                            .accessibilityIdentifier("clearSummaryDraft")
                        Button("Save summary") {
                            brief.summary = summaryDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                            editingSummary = false
                        }
                        .disabled(summaryDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("saveSummaryDraft")
                    }
                }
            }
        }
    }

    private func fieldLabel(_ name: String) -> some View {
        Text(name.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(1.3)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func simpleList(_ title: String, items: [String], icon: String) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.bold))
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 7) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                            .padding(.top, 7)
                        Text(item).font(.subheadline)
                    }
                }
            }
        }
    }

    private func routeIcon(_ route: InferenceRoute) -> String {
        switch route {
        case .onDevice: return "iphone.gen3"
        case .cloud: return "cloud"
        case .unknown: return "questionmark.circle"
        }
    }
}

#Preview {
    ContentView()
}

// Observe taps without taking touches away from editors or buttons.
private struct KeyboardDismissArea: UIViewRepresentable {
    final class TapView: UIView, UIGestureRecognizerDelegate {
        private var tap: UITapGestureRecognizer?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let tap { tap.view?.removeGestureRecognizer(tap) }
            guard let window else { return }
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            window.addGestureRecognizer(recognizer)
            tap = recognizer
        }

        @objc private func dismissKeyboard() { window?.endEditing(true) }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var view = touch.view
            while let current = view {
                if current is UITextField || current is UITextView || current is UIControl { return false }
                view = current.superview
            }
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }

    func makeUIView(context: Context) -> TapView { TapView() }
    func updateUIView(_ uiView: TapView, context: Context) {}
}
