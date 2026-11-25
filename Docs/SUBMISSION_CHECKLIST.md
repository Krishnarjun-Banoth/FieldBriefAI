# #BuildHybridAI 2026 — Remaining submission gates

Deadline: November 30 at 2 PM Pacific / December 1 at 3:30 AM India time.
Official source: https://firebasehybridaihackathon.devpost.com/rules

## Implemented and checked

- [x] Local Firebase AI Logic generation and cloud-consent UI implemented; earlier iPhone verification recorded.
- [x] Saved sites, visit history, completion notes and reopen events implemented.
- [x] PDF sharing and Files backup/restore implemented; earlier phone verification recorded.
- [x] 19 core tests pass on November 22.
- [x] Expanded backup/recovery/site-isolation regression passes on November 22.
- [x] Source/document credential-pattern scan passes; private Firebase configuration excluded from publishing.

## Still required or unproven

- [x] Fresh iPhone non-cloud UI regression: 5 tests passed, zero failures on November 22; Gemini excluded. PDF export retains earlier evidence rather than a fresh test today.
- [ ] Successful Gemini call and actual hybrid fallback, with route and consent evidence.
- [ ] Working judge access free of charge through December 16; temporary sprint access alone does not establish this.
- [ ] Public source repository, license, setup instructions, dependency attribution, and summary of work created during the contest.
- [ ] Public English demonstration video, within the rules’ length requirement.
- [ ] Final Devpost fields and submission before deadline.
- [ ] Founder eligibility and ownership attestations.

## Score evidence, beyond eligibility

- [ ] Small synthetic model evaluation: commitment recall, invented facts, owner/deadline accuracy, route and latency. Parser tests alone are not model-quality evidence.
- [ ] Real field-user feedback and corrections, with permission to quote any results.
- [x] Optional cross-visit comparison implemented; one real on-device positive case passed. Broader negative/ambiguous model evaluation remains open.

Publishing, final submission, billing changes, and contacting others require the applicable user authorization. Continue local reversible preparation within the authorized scope.

## Day 1 readiness review — November 25

- Fresh core suite passed, 28 tests and zero failures. The prior November 23 iPhone run passed eight local comparison scenarios and a separate save-and-confirm check. No new physical-device run was performed today.
- The source and documentation credential-pattern scan found no obvious matches. Exclude the private local Firebase configuration and all build output from any public package. Review the exact export before publishing. The local project includes an MIT license and a README. No public repository or judge build was verified.
- Devpost confirmed the quota request rolls into Sprint 3. No allocation email was found in the CHIMJA inbox during this review. Allocation decisions are due November 27. The existing project's last live Gemini test returned a free-tier access error.
- If Sprint 3 access arrives, verify a direct Gemini call with fictional notes, then separately test the ordinary hybrid route with local inference unavailable and explicit consent. Capture the route indicator in each test. Verify durable free judge access independently through the judging close, December 17 at 3:30 AM IST.
- The revised two-visit demo outline is ready for internal recording. Its cloud segment depends on live evidence. Public video, public repository, final testing instructions and Devpost submission remain open.
