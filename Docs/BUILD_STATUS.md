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
