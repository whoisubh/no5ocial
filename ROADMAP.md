# no5ocial Roadmap

## Phase 0 — Feasibility (before building the scheduler)
- Inventory every social account, account type, owner/admin, and intended content formats.
- Create developer apps for candidate platforms.
- Confirm official API access and required reviews.
- Estimate API costs, especially X.
- Choose the first platform based on feasible access, publishing volume, and value saved.
**Exit gate:** a written capability/cost matrix with no unknown blocker for the first integration.

## Phase 1 — Useful internal MVP
- Brand/account registry (manual records are okay initially).
- Media library and caption drafts.
- Destination selector and platform-specific variants.
- Preflight checklist.
- Manual publishing handoff with copy/export/share.
- Publish history and per-destination status.
**Exit gate:** team can prepare one post for multiple accounts without re-entering content from scratch.

## Phase 2 — First official integration
- OAuth connection and reconnect flow.
- Server-side adapter.
- Publish now for one supported format.
- Durable attempts, errors, provider post URL.
- Tests for success, invalid media, revoked token, rate limit, and ambiguous timeout.
**Exit gate:** successful end-to-end test with real authorized account, plus failure recovery.

## Phase 3 — Scheduling
- Durable queue and server worker.
- Calendar and timezone handling.
- Cancel/reschedule rules.
- Retry/backoff and duplicate safeguards.
- Notifications for Action Required/Failed.
**Exit gate:** worker can process due jobs without the Flutter app running.

## Phase 4 — Additional platforms
- Add platforms individually after access/cost verification.
- Add format-specific media checks and previews.
- Track cost per successful destination.
**Exit gate:** each adapter meets its own integration test checklist.

## Phase 5 — Optional improvements
- Bulk content import/export.
- Analytics if official endpoints and permissions are worthwhile.
- Team approvals and roles.
- AI-assisted caption variants with user review.
- Public SaaS only after internal retention, support, compliance, and cost economics are understood.

## Do not prioritize yet
- Complex analytics, competitor tracking, AI auto-posting decisions, social inbox, public billing, multi-tenant onboarding, or broad “every platform” claims.
