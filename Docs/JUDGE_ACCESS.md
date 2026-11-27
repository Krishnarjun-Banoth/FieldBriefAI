# Judge setup and access — source/local available; independent cloud not certified

Supported target: iPhone with iOS 26+ and Apple Intelligence supported, enabled, and downloaded; English interface. Development evidence used iPhone 16 / iOS 26.5 and Xcode 27.1 RC. Simulator UI runs do not prove real on-device inference.

## Source setup

1. Clone the public source repository. Founder approved publication on November 27. Install Xcode and XcodeGen. Run `xcodegen generate` and select your development team in Xcode for the app and test targets.
2. For the Firebase AI Logic runtime path, add your Firebase iOS configuration privately at `FieldBriefAI/Configuration/GoogleService-Info.plist` (create the folder if needed), for bundle ID `com.chimja.fieldbriefai`. Rerun XcodeGen after adding it.
3. Configure Firebase AI Logic and App Check using an authorized project. Debug builds use debug attestation; register the generated token privately in Firebase Console. Do not post credentials or tokens in the repository or submission. Release App Attest is not verified by the Debug test evidence.
4. Keep personal billing disabled for no-cost testing. If Gemini is not available, local processing still works on a ready physical device; the cloud failure must be reported honestly. Without Firebase config, the direct Apple fallback is available but does not establish Firebase runtime integration.
5. Run core tests with `swift test --build-system native`. Run UI checks selectively; cloud tests make real calls when enabled.

## Review task

Use fictional sites and notes. Save a first visit containing an open filter task; return to that site, enable comparison, and enter a clear filter-completion note. Review the brief and evidence, save the second visit, then explicitly confirm the candidate. Reopen the site and inspect history and the saved report. Try an uncertain note and confirm no follow-up is automatically closed. Export a private backup before any restore, because restore replaces history.

## Organizer clarification received November 27

Devpost Credits confirmed that Sprint 3 accounts/projects are deleted after Monday, November 30; they cannot be extended and there is no separate evaluation arrangement. The organizer says judging access should use the entrant's own project and that judges are not required to run it. The recorded demonstration therefore preserves the actual live hybrid evidence, while the repository supplies the independently buildable local application and Firebase setup instructions.

[Approved video demonstration](https://youtu.be/dhCNSl4RlGE).

No TestFlight/App Store build or durable configured Gemini judge backend is supplied. With no Firebase plist the direct Apple path is available on a ready device; this path does not establish Firebase integration. To exercise Firebase at runtime, add an authorized Firebase configuration and App Check setup as above. Free-tier eligibility must be verified for that project; do not enable personal paid billing. We do not promise cloud access throughout judging from the temporary project.

Never distribute the temporary login or debug token. Source setup requiring a judge's project is a documented limitation, not a claim of unrestricted ready-to-run cloud access.

## Maintainer live-test safeguard

Live cloud UI tests skip by default. To run them deliberately on an approved test project, supply `FIELDBRIEF_RUN_LIVE_CLOUD=1` and the private `FIELDBRIEF_APP_CHECK_DEBUG_TOKEN` in the XCTest runner's environment. The test forwards the token as `FIRAAppCheckDebugToken` only to the app process. Keep the token and any generated xctestrun file private; do not commit them. `testOptInGeminiGeneration` exercises direct cloud after consent; `testHybridFallbackWhenLocalUnavailable` uses the ordinary hybrid path and skips if the local model is available. Neither a skip nor a backend-only HTTP success proves the full fallback journey.

The additional `testHybridFallbackAfterRealLocalContextFailure` supplies high-token fictional inventory notes within the character limit. It uses an available real primary model and the normal hybrid session; its Gemini route passed on iPhone November 27. It does not change device settings or inject an unavailable-model response. Debug tokens must be configured separately for each judge's launch environment; Release App Attest remains unverified.
