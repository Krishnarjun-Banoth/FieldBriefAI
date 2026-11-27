# Build and verification record — 22 November 2026

## Product implemented

- Firebase AI Logic on-device generation, editable structured briefs, explicit consent for cloud fallback.
- Saved sites and visits, follow-ups, completion notes linked to later visits, reopen event history.
- Saved visit reports, PDF sharing, backup preview and confirmed restore.
- Recovery preserves unreadable history before replacement.

## Fresh evidence on 22 November

- Swift Package core suite: 19 tests passed, zero failures.
- Expanded isolated history regression passed: completion/reopen history, legacy archive migration, corrupt-file recovery, continued saving after relaunch, unsupported backup versions, duplicate site IDs, missing site references, missing origin visits, and cross-site completion rejection.
- Credential-pattern scan passed for the source and documentation paths inspected. Local Firebase configuration remains private; this scan is not a guarantee that a release package contains no secrets.
- Fresh iPhone 16 non-cloud UI suite passed: 5 tests, zero failures, about 123 seconds. Covered Files backup/restore, consent, initial screen, real local generation, and saved visits with completion/reopen history after relaunch. Gemini test explicitly excluded. Earlier simulator startup stalled; the subsequent physical device pass closes that regression gap.
- Result bundle: `/tmp/FieldBrief-NonCloud-Unlocked-Nov22.xcresult`. This suite does not reverify PDF export or second-device migration.

## Earlier evidence and limits

- Prior iPhone runs and manual user checks covered local generation, saved visits, follow-up completion/reopen history, PDF share preview and Files backup/restore.
- November 21 live Gemini request returned HTTP 403: free tier unavailable for this project. Test skipped; no cloud-generation pass claimed.
- Forced cloud mode, when successful, will prove cloud access; actual hybrid fallback needs its own evidence.
- Second physical iPhone restore has not been tested.
- No claim of real-user field impact or measured extraction accuracy yet.

## Remaining competition work

- Organizer test-account access, successful Gemini and hybrid fallback validation, and judge access through December 16.
- Public source package with setup and third-party attribution, final Devpost submission, and public English video.
- Cross-visit AI comparison implemented after user authorization on November 22; see current verification below.
- Real-user feedback must come from actual participants; synthetic tests cannot establish market impact.

## Site-list usability improvement

- Added visit counts and open follow-up counts to each site row, plus an empty search result message.
- Device build passed. Targeted iPhone history test passed on November 22, checking the two-visit/two-open-follow-up summary after relaunch and existing completion/reopen history.
- This targeted run does not verify every search interaction or PDF export.

## Cross-visit comparison — November 22

- Optional comparison uses the selected site's latest summary and up to eight open follow-ups. Cloud consent discloses prior-history use.
- Model proposes changes and completion references. Excerpt references resolve to exact current-note text; unknown action IDs, duplicate proposals, unmatched quotes and out-of-range excerpts are rejected. This is evidence validation, not a semantic correctness guarantee.
- Save the new visit before confirming an individual resolution. Confirmation records an event and evidence note against that visit; historical briefs remain unchanged. Changes are retained in saved reports and labeled AI output requiring review.
- 24 core tests pass; recovery/backup regression and credential-pattern scan pass.
- Real on-device comparison UI test passed on iPhone 16 with cloud off, using a focused fictional filter-replacement example (about 44 seconds including navigation). This is a single positive integration case, not a general accuracy benchmark.
- Earlier real-model attempts omitted valid evidence or returned unexpected field types. Parser and prompt were revised; wider ambiguous/negative model evaluation remains necessary.

- Final targeted iPhone run: both real-model comparison and synthetic confirmation-flow tests passed, 2 tests with zero failures (about 83 seconds of test execution). Result: `DerivedData/Logs/Test/Test-FieldBriefAI-2026.11.22_15-06-35-+0530.xcresult`.

## Quota update — November 23

Devpost Credits replied: identity verification arrived November 19, after the Sprint 2 list cutoff. No Sprint 2 account was allocated. Request automatically moves to Sprint 3 without resubmission; selection follows November 25 cutoff, with account emails scheduled November 27. Allocation is limited and not guaranteed.

If approved, access is a separate temporary Google account and Cloud project. Organizer says no credit card/billing account needs to be added and no charge to the participant. Account lasts about four days and the project is deleted on expiry; code survives. This does not enable free-tier access on the existing CHIMJA project or resolve judge cloud access after expiry.

## Comparison reliability evaluation — November 23

Eight real on-device scenarios executed with cloud off. Baseline exposed false completion suggestions. Added conservative explicit-completion/task-overlap checks and tolerant handling of malformed optional suggestions. Revised run met 6 of 8 scenario expectations; missed the clear completion and returned malformed brief JSON for ambiguous notes. Scenario suite FAILED with two failures. No automatic action completion occurred in the seven runs that reached state verification. 26 core tests pass. See COMPARISON_EVALUATION.md for exact limits and remaining work. This supersedes any implication that the single November 22 positive pass establishes broad reliability.

## Follow-up reliability fixes — November 23

- Preserved valid briefs when optional decision lists contain non-text entries; do not reinterpret those entries as decisions.
- Added clearly labeled conservative literal-match candidates alongside model suggestions, retaining explicit user confirmation and same-site checks.
- Comparison local generation now uses greedy sampling and a 1,200-token response bound.
- Final eight-scenario real on-device application-level test passed, zero failures; generation-to-review 4–5 seconds in this small run. This measures the combined model/validation/matching workflow, not unaided model accuracy or all brief factuality.
- 28 core tests pass. Previous failing evaluation is retained for transparency; see COMPARISON_EVALUATION.md for limits.

- Final focused iPhone confirmation-flow regression passed after the fixture was changed to isolated completion-only notes. Confirms save-before-review and completed follow-up visibility. Result: `DerivedData/Logs/Test/Test-FieldBriefAI-2026.11.23_09-38-10-+0530.xcresult`.

## Final local readiness pass — November 27

- Fresh simulator build succeeded using Firebase 12.19.3.
- Fresh core suite: 28 tests, zero failures. Executed with `swift test --scratch-path /tmp/fieldbrief-core-final-nov27 --build-system native`; scratch path avoids Finder extended metadata that prevented the first attempt's test-bundle signing.
- Standalone corrupt-history recovery regression passed. Source/doc credential-pattern scan passed.
- Prior real iPhone evidence remains as recorded above. No new live Gemini success has been established.
- Sprint 3 supplied account login and assigned project access verified. Firebase onboarding reports existing Cloud billing and would select Blaze. Stopped before continuing under the no-paid-billing restriction; organizer-funded-only approval is pending. No personal billing changed.

### Sprint 3 configuration follow-through

Founder approved using only the organizer-funded project without billing changes. Firebase and the iOS app were provisioned, optional Analytics and AI monitoring disabled, Gemini Developer API setup completed, and AI Logic App Check enforcement is enabled. Founder supplied the downloaded plist; its project and bundle IDs match. It is installed only in the ignored workspace configuration path; original developer-project config remains unchanged. A private debug token is registered for test use.

An earlier targeted device invocation reported TEST SUCCEEDED but its xcresult contained zero selected tests. It is not verification evidence. Corrected selections include the test class; no fresh UI pass is claimed until actual test counts are verified.

### Live backend connectivity — November 27

Using only the organizer's assigned project and its registered private debug token, App Check token exchange returned HTTP 200. A synthetic 32-output-token-limited request through the Firebase AI Logic proxy returned HTTP 200, model `gemini-3.5-flash-lite`, text “connection verified”. This is actual backend generation with App Check, not a mock. It does not establish app-level routing, consent UI, structured-brief quality, or ordinary hybrid fallback; those require separate device/simulator evidence.

### Final iPhone runtime evidence — November 27

Signed build-for-testing succeeded. Verified xcresult summary: four targeted iPhone tests passed, zero failures/skips (80.447 seconds): cloud-consent cancellation, real on-device generation with cloud off, real direct Gemini generation after consent, and isolated save-before-confirm comparison. Result: `/tmp/FieldBrief-Sprint3-Device-Final-Nov27.xcresult`.

Separate ordinary-hybrid stress test passed on iPhone 16. The local model was initially available, the input stayed within the character limit but contained high-token synthetic inventory markers, and the normal hybrid session returned a Gemini brief. No `-testGeminiCloud` flag or substituted processor/error was used. Source SDK falls back on initial primary inference failure. This supports actual error-path fallback under that stress input; it does not verify every failure type or identify the precise primary error from the UI assertion alone. Result: `/tmp/FieldBrief-Sprint3-ContextFallback-Nov27.xcresult`.

The iOS 26.5 simulator's unavailable-model test skipped because its real local model was available; not counted as a fallback success. Earlier simulator startup attempts were interrupted and do not count as regression passes. The original developer-tree tests/config were restored after producing the signed temporary-project test bundle; the workspace plist remains private and ignored.


### Recording and review hardening — November 27

- Normal launch now opens with empty notes and no sample-note control. The sample control is opt-in for DEBUG UI tests only.
- Draft summaries have an explicit Edit summary sheet with Clear, Cancel and Save controls. A targeted iPhone editing check passed on the latest retry; the full real-inference recording is tracked separately.
- Unsupported draft actions can be removed before saving. Recorded corrected summaries must be labeled as reviewed output, not unaided model accuracy.
- A narrow completion matcher regression handles “before next visit” deadlines while retaining uncertainty and prerequisite guards. Core suite increased to 29 passing tests in the preceding implementation pass.
- Invalid DEBUG history identifiers now use isolated throwaway storage. Recording data is kept separate from normal user history. See DEMO_SCRIPT.md for the corrected early-capture incident and privacy controls.
- The initial resumed capture failed before app checks because iPhone UI automation could not initialize. It is not an app-test pass; the subsequent retry reached and passed the editing check.


### Final clean capture retry — November 27 evening

Two selected iPhone UI tests passed with zero failures: the dedicated summary editor and the real on-device two-visit maintenance walkthrough. The latter generated and reviewed both briefs, saved two visits, confirmed the filter resolution, asserted exactly one open follow-up and one completed follow-up, opened the later report/PDF share sheet, and showed backup controls after relaunch. The earlier failed automation initialization is retained as a failed attempt, not silently counted as a pass. Evidence: ignored `Artifacts/demo/final-run/ReviewCaptureRetry.xcresult` and its exported summary.

The normal user archive was copied after capture and compared as parsed JSON with the private baseline: exact match. The app was then launched normally without test arguments. Capture used an isolated UUID history and fictional maintenance data. The text editor probe used a fixture; its recording is excluded from the review video. The main walkthrough used real local inference, and the cloud segment uses the separately verified normal hybrid stress path. Personal share suggestions are redacted; source audio is excluded. All assets remain private pending founder review.
