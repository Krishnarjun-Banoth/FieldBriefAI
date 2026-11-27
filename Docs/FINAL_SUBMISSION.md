# FieldBrief AI — submission copy for founder review

Status: internal draft for founder review, not submitted. Live cloud and one genuine hybrid stress case passed; the organizer confirmed no extension; independent judge cloud access is not certified.

## Project name and tagline

FieldBrief AI — Turn field visits into reviewed reports and clear follow-ups.

## Problem and audience

Maintenance teams returning to customer sites need to remember what was observed, what was promised, and what remains open. Rough notes and separate reports make that continuity difficult. FieldBrief AI is an iPhone prototype that keeps reviewed visit briefs and follow-ups together under each site.

## What it does

Generate an editable structured brief from field notes, save it to a site, revisit earlier reports, track follow-ups, record completion evidence against a later visit, share a PDF, and export or restore history through Files. Optional comparison uses the latest saved summary and up to eight open follow-ups. The app proposes changes and completion candidates; the user reviews them, saves the visit, and confirms each completion. Previous reports remain intact.

## Firebase AI Logic and hybrid architecture

With Firebase configured, on-device generation uses Apple Foundation Models through Firebase AI Logic. Cloud fallback is off by default. After explicit permission, a Firebase AI Logic hybrid session uses the Apple system model first and Gemini as secondary. App Check protects the Firebase path. The route indicator reports the processing model when available.

Prior summaries and follow-ups are included in inference only when comparison is enabled. Cloud consent discloses that prior-visit context can accompany the current notes. Local generation does not imply the entire application makes no network connections: Firebase initialization and App Check can communicate with their services.

## What was built during the contest

The SwiftUI app, structured note-to-brief pipeline, Firebase AI Logic integration, consent controls, site and visit persistence, follow-up completion/reopen history, PDF export, backup recovery, optional cross-visit comparison, and automated verification were developed during the contest. The app builds on Apple platform frameworks and Firebase dependencies. AI coding assistance was used. Dependency licensing notices accompany the source.

## Evidence and limits

Previously verified on iPhone 16: real local inference, consent, saved visits after relaunch, completion/reopen history, Files backup/restore, and manually inspected PDF output. Eight fictional comparison scenarios matched expected application-level behavior in the final November 23 run. That result includes conservative validation and literal matching; it is not a claim that the raw model classified every case correctly. The established baseline had 28 passing core tests; the latest deadline-matching regression increased that to 29. The final recording retry also passed two selected iPhone tests: explicit summary editing and the real local two-visit walkthrough.

Live backend connectivity passed November 27 using the organizer-funded temporary project: App Check exchange and a minimal synthetic Gemini 3.5 Flash Lite request through Firebase AI Logic both returned HTTP 200. Four targeted iPhone tests then passed: consent cancellation, real local generation with cloud off, direct live Gemini after consent, and save-before-confirm comparison. A separate ordinary-hybrid test passed under synthetic high-token input with the real local model initially available, returning the Gemini route without a forced-cloud flag or mocked model. This is one stress case, not a broad fallback reliability benchmark. The organizer confirmed that temporary projects are deleted after November 30, cannot be extended and have no separate evaluation arrangement. Source/local operation remains independently available; configured judge cloud access is not certified.

No field-user impact study has been completed. English completion guards deliberately suppress uncertain or mixed positive/future notes; manual completion remains available. The app is a prototype, without team sync, authentication, or automatic cloud history backup. Models can invent or misunderstand content; summaries, owners, dates and decisions need human review. This is not a production reliability claim.

## Publication gates

Before final submission: approve public repository visibility; supply the public English YouTube video (at most 3 minutes); confirm usable judge access through the judging close; complete founder eligibility/ownership attestations and final Devpost submission.
