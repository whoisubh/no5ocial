# Product Requirements Document — no5ocial

**Status:** Initial proposal  
**Product owner:** Shaadow  
**Product type:** Internal social media operations tool  
**Primary platform:** Flutter mobile app; responsive web/admin surface may follow  
**Primary market:** Shaadow's own portfolio of brands and social accounts

## 1. Problem
Shaadow publishes across multiple brands and platforms. Team members repeatedly upload the same or adapted content to separate accounts, manually track what has been published, and switch between apps. Paid social schedulers are not currently justified by the team's budget.

## 2. Product vision
no5ocial becomes the single place to organize social content, choose destination accounts, adapt copy/media for each network, publish or schedule where officially supported, and clearly manage the remaining manual steps.

## 3. Goals
- Reduce repetitive publishing work and context switching.
- Prevent missed, duplicate, or incorrectly targeted posts.
- Reuse one content asset while allowing platform-specific versions.
- Provide transparent status per destination: Draft, Scheduled, Publishing, Published, Action Required, Failed, Cancelled.
- Keep operating costs low and visible.
- Respect official APIs, account permissions, rate limits, and platform policies.

## 4. Non-goals for MVP
- Replacing a full social analytics suite.
- Automated engagement, follow/unfollow, mass commenting, scraping, or DM automation.
- Circumventing API restrictions with browser automation or unofficial endpoints.
- Guaranteed publishing to every format on every platform.
- Public multi-tenant SaaS, billing, team roles, and agency client portals.
- AI content generation as a prerequisite. It can be added later as an optional assistive feature.

## 5. Users and jobs
### Primary user: Shaadow content operator
- I want to upload an asset once and reuse it across selected accounts.
- I want to edit captions separately per platform without duplicating the whole post.
- I want to see which destinations are ready, scheduled, published, or blocked.
- I want to know why a destination cannot publish automatically and what to do next.
- I want to avoid accidental publishing to the wrong brand/account.

### Secondary user: Founder/approver
- I want to review the publishing queue and confirm the brand voice.
- I want a record of what was published, when, where, and with what final caption.
- I want to see operational cost and time saved.

## 6. Brand and account model
A **Brand** is a content identity, e.g. Shaadow, Shaadow Works, Boofer, Favtunes, Galaxious, Owl and Fowl Studios. A **Social Account** is a connected destination under a platform, e.g. Instagram @boofer and YouTube channel Owl and Fowl Studios. One brand may have many social accounts; a social account belongs to one brand. Keep these concepts separate.

Initial account inventory (confirm handles and access before configuration):
- Instagram: Shaadow, Shaadow Works, Boofer, Owl and Fowl Studios.
- YouTube: Shaadow, Owl and Fowl Studios.
- LinkedIn: Shaadow Platforms organization page.
- X: Boofer, Shaadow.
- Additional platforms/accounts are configuration, not hard-coded assumptions.

## 7. Core workflows
### A. Create content
1. Create a post draft.
2. Add one or more media assets.
3. Select brand and content type.
4. Select destination accounts.
5. Generate a default caption/copy, then edit per destination.
6. See validation and preview per platform.
7. Save draft, publish now, schedule, or send to manual handoff.

### B. Publish to multiple destinations
1. Validate each destination independently.
2. Show blockers before submission (unsupported format, missing permission, missing media, caption constraints, missing alt text if applicable).
3. Create one publishing job per destination; never treat a multi-destination publish as a single all-or-nothing transaction.
4. Record status, provider response, external post ID/URL, timestamps, and safe error summary.
5. Retry only retryable failures, with idempotency protection and duplicate-risk warnings.

### C. Manual publishing
For a destination that cannot publish via an approved API:
1. Prepare caption and asset in a platform-specific handoff view.
2. Offer copy caption and export/share asset actions supported by the OS.
3. Mark as manually published only after user confirmation; optionally capture the post URL.
4. Clearly label it Manual, never pretend it was API-published.

### D. Schedule
1. Choose local date/time and timezone.
2. Validate destination support and account connection at schedule time.
3. Queue a separate job for each destination.
4. Revalidate permissions and media shortly before publishing.
5. Show late, failed, and action-required jobs prominently.

## 8. MVP functional requirements
- FR-01 Brand management: create/edit/archive brand.
- FR-02 Account registry: platform, handle/name, associated brand, connection status, supported capabilities.
- FR-03 Content library: drafts, media, captions, tags, campaign, notes.
- FR-04 Multi-select destinations.
- FR-05 Platform-specific caption overrides.
- FR-06 Media validation and per-platform preview.
- FR-07 Publishing queue and calendar/list views.
- FR-08 Independent per-destination publishing status.
- FR-09 Scheduled publishing only where official APIs support it.
- FR-10 Manual publishing handoff for unsupported cases.
- FR-11 Retry/error handling with duplicate safeguards.
- FR-12 Audit log of changes and publishing events.
- FR-13 Connection management, reconnect/reauthorize, token expiry indicators.
- FR-14 Exportable post history (CSV can be post-MVP).
- FR-15 Basic operational dashboard: drafts, scheduled, published, failed, action required.

## 9. Acceptance criteria
- A user can create one draft and assign at least two destinations.
- Each destination can have a different caption and media variant.
- Invalid destinations are blocked before publishing, with actionable explanations.
- A partial failure does not erase successful publications to other destinations.
- Retrying a job does not blindly duplicate a post; the UI warns when duplicate risk cannot be ruled out.
- Each completed destination stores provider post ID/URL where returned.
- Expired/revoked connection status is visible and does not silently fail.
- A manual handoff cannot be misrepresented as an automatic publication.
- No long-lived platform token or client secret is shipped in the Flutter binary.
- All timestamps are stored in UTC and displayed in the user's configured timezone.

## 10. Non-functional requirements
- Security: least-privilege OAuth scopes, encrypted secrets, no credentials in logs.
- Reliability: durable queue, bounded retries, idempotency where possible.
- Observability: structured logs, correlation IDs, provider latency/error tracking.
- Accessibility: readable contrast, scalable text, semantics labels.
- Performance: responsive library and queue on typical Android devices; paginate large lists.
- Maintainability: adapter-based platform integrations and automated tests.
- Privacy: collect only content/account metadata needed for operation.

## 11. Success metrics
Measure against a two-week manual baseline:
- Median time from approved asset to publishing across all target accounts.
- Minutes saved per campaign.
- Percentage of destination jobs completed without intervention.
- Failure rate by platform and failure category.
- Duplicate-post incidents.
- Number of manual steps remaining per destination.
- Monthly infrastructure + API cost per successful destination.
Initial target: reduce repetitive publishing time by at least 50% for workflows supported by the MVP, without increasing publishing errors.

## 12. Risks and assumptions
- API access and app review may take longer than coding.
- Platform support differs by account type and content format.
- X API charges may undermine a strict zero-cost requirement.
- Video upload and processing can be more complex than image/text posts.
- OAuth scopes and provider policies can change.
- A mobile-only background scheduler may not execute reliably when the app is closed; scheduling must run on a server/worker.
- Some platforms may require additional verification or compliance review.

## 13. MVP release gate
Do not call the MVP complete until: one official integration works end-to-end in production-like conditions; failures are visible and recoverable; secrets remain server-side; and manual fallback is usable for accounts not yet approved for automation.
