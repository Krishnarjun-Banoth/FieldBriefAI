# FieldBrief AI — CHIMJA Labs

An iPhone prototype for maintenance teams returning to customer sites: turn field notes into an editable brief, save visits under the right site, track follow-ups, and share a visit report. Built for #BuildHybridAI 2026.

**On-device generation is the default. Gemini cloud fallback requires explicit opt-in.** With Firebase configured, local generation uses Apple Foundation Models through Firebase AI Logic.

> Verification status — November 14, 2026: on-device generation and the main visit workflow have been exercised on an iPhone 16. Live Gemini fallback remains unverified. This is a development prototype, not a production release. See the verification table below for the scope of each check.

## Main workflow

1. Choose or add a site with a client name and site name.
2. Enter synthetic or approved, sanitized notes, or use **Demo notes**. Input accepts 20–4,000 characters.
3. Leave **Allow cloud fallback** off to generate locally. Review the processing-location banner and edit the brief title, summary, action owners, and due dates.
4. Tap **Save Visit** to retain the brief under the selected site. An existing saved draft can be updated; generating a new brief starts a new visit draft.
5. Return to the site to see visit history and follow-ups. Mark a follow-up complete, optionally add a completion note, and optionally link it to a later visit at that site.
6. Open a saved visit to read its report and use **Share PDF**. The editor also supports copying or sharing the brief as Markdown text.
7. In **Sites → Backup and restore**, export a backup to Files. Importing a backup previews site and visit counts, then requires confirmation before replacing the current history. Restore replaces history; it does not merge it.

The AI currently processes the latest notes only. It does not compare visits, automatically resolve follow-ups, or infer updates from site history. Completion links are chosen by the user.

## Inference and consent

The runtime integration is in `FieldBriefAI/AI/FirebaseHybridNoteService.swift`:

- **Cloud off, Firebase configured:** a Firebase AI Logic on-device session uses Apple Foundation Models. This branch does not construct a Gemini generation session.
- **Cloud off, Firebase missing:** the prototype can use Apple Foundation Models directly. This setup is useful locally but does not demonstrate Firebase runtime integration for judging.
- **Cloud on:** after the consent dialog is accepted, a Firebase hybrid session uses Apple Foundation Models as primary and Gemini 3.5 Flash-Lite as secondary. Firebase configuration and usable cloud quota are required.
- **Local model unavailable, cloud off:** generation is blocked with availability information; it does not silently send notes to the cloud.

Cloud fallback defaults to off on a fresh app launch. The hybrid result banner uses the response's model version to identify its source. Enabling fallback does not guarantee that a particular request uses Gemini. The cloud route and actual fallback behavior still need successful end-to-end verification.

Debug-only UI fixtures generate synthetic briefs for persistence tests. They are not evidence of real AI output quality and are excluded from Release builds. The debug cloud-only test mode still requires consent and is separate from testing genuine hybrid fallback.

## Local data and privacy

- Saving a visit persists its generated/edited brief, site association, date, and follow-ups on the device. Completion notes and visit links are also saved. Raw input notes are not retained in the saved-visit record.
- Unsaved editor content has no recovery guarantee. Save a visit before relying on it being available after relaunch.
- History is written atomically to the app's Application Support directory with complete file protection. There is no app-managed team sync or automatic cloud history backup.
- Exported backups are readable JSON containing client/site information, briefs, and follow-ups. They are not password-encrypted. PDFs and backups leave the app only through user-initiated export; the destination may itself use a cloud service.
- Firebase initialization and App Check may make network requests even with cloud inference off. Local generation is not a claim that the entire app makes no network connections.
- No analytics or user-account flow is implemented. No follow-up messages are automatically sent.
- AI output requires human review. Use fictional notes in demonstrations and testing.
- Keep Firebase configuration and App Check debug tokens local and outside version control. Never include tokens or private logs in screenshots, backups of the source, or submission materials.

## Development requirements

- A Mac with Xcode supporting the iOS 26 deployment target. Development builds have used **Xcode 27.1 RC**; the device workflow was tested on **iPhone 16 with iOS 26.5**.
- An Apple Intelligence-compatible physical device with Apple Intelligence enabled and its model ready for real on-device inference. Simulator UI tests do not establish physical-device inference behavior.
- XcodeGen to generate the Xcode project from `project.yml`.
- Swift Package Manager dependencies: `project.yml` specifies Firebase Apple SDK from version 12.13.0; the development checkout used 12.19.3.
- For Firebase integration, your own Firebase project, Gemini Developer API setup, App Check registration, and an iOS app matching `com.chimja.fieldbriefai` (or consistently change the bundle ID).

## Local setup

1. Install the required development tools. Run `xcodegen generate`, open `FieldBriefAI.xcodeproj`, and select your signing team.
2. For Firebase-backed testing, register the iOS app in a separate Firebase project and place its downloaded configuration at `FieldBriefAI/Configuration/GoogleService-Info.plist`. This path is ignored by version control.
3. Configure Firebase AI Logic with the Gemini Developer API and register the app for App Check. Keep the project on Spark for no-cost work; do not enable billing to work around a quota error.
4. Debug builds use the App Check debug provider. Register the locally generated token in Firebase Console, keeping both token and diagnostic logs private. Release builds select App Attest and require matching Apple capability/entitlements and Firebase registration; Release attestation has not been verified end to end.
5. Build and run on the supported iPhone. Confirm the on-device model is ready, leave fallback off, and generate a brief from synthetic notes.
6. Test Gemini separately after confirming free quota is available and explicitly enabling cloud fallback. Record whether the result actually came from Gemini. A working local result does not verify cloud access.

The existing founder project has App Check registration and baseline enforcement configured. A fresh developer setup still needs its own valid configuration and App Check credentials. No credentials are shipped with the source.

## Tests and evidence

Run the core suite from the project directory:

```sh
swift test
```

Run the isolated corrupt-history recovery regression on macOS:

```sh
xcrun swiftc -parse-as-library \
  FieldBriefAI/Core/Brief.swift \
  FieldBriefAI/Features/VisitHistory.swift \
  scripts/HistoryRecoveryCheck.swift \
  -o /tmp/fieldbrief-recovery-check
/tmp/fieldbrief-recovery-check
```

This check uses temporary sample files and removes them afterward. It verifies that invalid versions, duplicate IDs and broken backup relationships are rejected without changing live history; cross-site completion is rejected; completion and reopen events survive backup; unreadable history is preserved before recovery; and restored history remains writable after reopening.

For UI tests, generate the project and choose an available destination in Xcode's FieldBriefAI scheme. The tests use isolated history and synthetic fixtures for persistence scenarios. Real-generation tests require a ready model and appropriate device/configuration; review the selected test before running it. Protect Xcode logs because Debug App Check may print a token.

| Area | Evidence and remaining limits |
|---|---|
| Core validation, parsing, Markdown, inference policy | 19 tests passed on November 14, 2026, including preservation of seven actions through parsing and export. |
| Firebase-backed on-device generation | Real iPhone generation verified with cloud fallback off; manual and automated checks. No broad output-quality benchmark yet. |
| Sites and saved visits | Physical-device automation exercised saving and relaunching isolated sample histories. |
| Follow-up completion and later-visit link | Physical-device test verified the note in the linked visit's in-app report after relaunch; the original report remained unchanged in that tested flow. |
| PDF sharing | Physical-device automation opened the PDF share sheet; founder manually saved and reopened a PDF and checked its layout. |
| Backup through Files | Empty and populated sample backups exported and restored into fresh isolated history on the same iPhone. |
| Corrupt-history recovery | New source fix passed the isolated macOS regression. Not yet installed or tested through the iPhone UI. |
| Different-device migration | Not verified. The simulator Files attempt did not complete, and a second physical iPhone was unavailable. |
| Gemini and genuine hybrid fallback | Still unverified end to end on the iPhone; quota/access remains an open item. |
| Release App Attest | Provider selected in code; Release runtime verification pending. |

These are scoped checks, not a claim that every feature or edge case is validated. Persistence fixtures do not evaluate AI accuracy.

## Known gaps and next work

- Follow-up completion/reopening events now persist, including legacy completion migration. The new source checks cover relaunch and backup/restore; the updated UI still needs physical-device verification. Reports are not fully immutable audit records because saved briefs can still be edited.
- The prompt no longer caps action arrays at five. Evaluate real-model extraction quality; parser tests do not prove that a model captures every commitment.
- Add evidence-backed comparisons between visits with user-confirmed action updates.
- Verify live hybrid fallback and a sustainable no-cost judging setup; temporary quota alone does not establish ongoing availability.
- Validate a clean developer setup and Release signing/attestation before distribution.
- Test migration to a second physical device when one is available.

## Submission preparation

Registration and a Devpost draft exist. The public source repository, final demonstration video, judge access arrangement, and final submission are not complete. Publishing, uploading, spending, and submitting require separate founder approval.

`Docs/SUBMISSION_CHECKLIST.md` and `Docs/DEMO_SCRIPT.md` are planning drafts and need reconciliation with the current implementation before use. Submission claims should follow the verification table above and distinguish real inference from test fixtures.

## References

- [Competition overview](https://firebasehybridaihackathon.devpost.com/)
- [Official rules](https://firebasehybridaihackathon.devpost.com/rules)
- [Firebase hybrid inference for iOS](https://firebase.google.com/docs/ai-logic/hybrid/ios/get-started)
- [Hybrid configuration options](https://firebase.google.com/docs/ai-logic/hybrid/ios/configuration-options)
- [App Check debug provider](https://firebase.google.com/docs/app-check/ios/debug-provider)

## License

MIT; see `LICENSE`.

## Compare a return visit

Select a site with a saved visit and enable **Compare with last visit** before generating. The model receives the latest saved summary (up to 900 characters) and up to eight open follow-ups, scoped to that site. It proposes changes and possible completions; older reports are preserved. Comparison remains optional and off when changing sites.

Each completion suggestion must identify a supplied action and quote at least 12 characters found verbatim in the new notes. Unknown IDs, duplicate suggestions and unmatched evidence are rejected. These checks do not establish semantic correctness: review whether the quoted text actually confirms the full task is done. Save the new visit, then choose **Review completion** and confirm it. The confirmation is saved as a dated follow-up event linked to the new visit. No suggestion closes an action automatically.

Cloud consent includes prior-visit details when comparison is enabled. Synthetic UI fixtures verify controls separately from real-model comparison tests. One successful model example is not an accuracy benchmark.

Comparison completions combine model proposals with conservative literal task matches. A literal candidate can recover a model omission only when the current excerpt includes explicit past-completion wording and all meaningful task terms. Future/negative/uncertain notes suppress these candidates. This English vocabulary check is intentionally conservative, can miss valid completions, and is not semantic verification; the UI labels the combined source and requires confirmation. Malformed objects in optional text lists are discarded rather than promoted to agreed decisions.
