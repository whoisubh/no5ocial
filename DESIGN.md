# no5ocial Design Specification

## 1. Product character
no5ocial should feel like a calm, capable operations console, not a social network and not an analytics-heavy enterprise dashboard. The key interaction is: **one content item → many destinations → clear per-account outcomes**.

## 2. Design principles
- Destination clarity beats visual decoration.
- Make the next action obvious.
- Show account identity beside every publishing action.
- Treat partial success as normal; communicate status per destination.
- Never hide blockers behind generic error messages.
- Keep the composer fast on mobile.
- Make manual handoff a first-class workflow, not an embarrassing fallback.
- Avoid noisy gradients, gamification, or engagement vanity metrics in the MVP.

## 3. Visual system
- Background: light neutral (`#F7F8FA`); surfaces white (`#FFFFFF`).
- Primary text: deep charcoal (`#17191C`); secondary text `#656B73`.
- Primary action: dark ink/near-black with white text; optional restrained blue accent `#3659D9`.
- Success: accessible green; warning: amber; error: red; neutral: slate. Never rely on color alone—pair status with text and icon.
- Borders: `#E5E7EB`; radius 12–16 px; spacing scale 4/8/12/16/24/32.
- Typography: platform-native sans-serif; clear hierarchy; avoid tiny metadata.
- Icons: recognizable platform icons where licensing and asset rules allow; otherwise use consistent generic platform glyphs.

## 4. Information architecture
Bottom navigation (mobile):
1. **Home** — next scheduled posts, failed jobs, quick create.
2. **Content** — drafts, assets, published history.
3. **Calendar** — scheduled posts and date navigation.
4. **Accounts** — brands, connected profiles, permissions.
5. **Settings** — connections, timezone, storage, diagnostics.

Primary create action should be persistently easy to reach. On compact screens use a floating action button or prominent app-bar action.

## 5. Key screens
### Home
- Today's scheduled jobs and next 7 days.
- Action Required / Failed section at top when non-empty.
- Small summary: Drafts, Scheduled, Published this week.
- Quick actions: New post, Upload asset, Connect account.

### Content library
- Search and filters: brand, status, platform, campaign, media type.
- Each card displays thumbnail, title/first caption line, brand, destination count, and status.
- Bulk operations should be limited to safe actions; destructive actions require confirmation.

### Composer
- Step 1: Select brand and asset(s).
- Step 2: Select destination accounts grouped by platform and brand.
- Step 3: Shared caption with per-destination overrides.
- Step 4: Preview and validation.
- Step 5: Publish now / Schedule / Save draft / Manual handoff.
- Display each target as an account chip with avatar/icon, handle, and connection indicator.
- Provide an explicit “same caption everywhere” toggle; never silently overwrite destination-specific copy.
- Show media/caption compatibility warnings inline.
- Warn if the selected destination belongs to a different brand than the draft.

### Destination preview
- Tabs or dropdown per selected account.
- Render a best-effort preview, labelled as preview rather than exact simulation.
- Show effective caption and attached assets for that destination.
- Expose validation checklist and blocking reasons.

### Publishing queue
- One row/card per destination job, grouped under the source content.
- Status labels: Draft, Scheduled, Publishing, Published, Action Required, Failed, Cancelled.
- Show scheduled time in local timezone, attempts, last error, and external post link if available.
- Retry action only when safe; show duplicate-risk confirmation if the provider outcome is uncertain.

### Accounts
- Brand grouping.
- Platform, handle/page/channel, connected/reconnect state, supported formats/capabilities.
- Last verified connection time and required scopes (human-readable).
- Disconnect action with confirmation and warning about scheduled jobs.

### Manual handoff
- Caption copy button.
- Download/share media action.
- Platform-specific checklist.
- “I published this manually” confirmation and optional URL field.
- Clearly marked as manually confirmed.

## 6. Interaction states
Every async operation needs loading, success, empty, and error states. Use optimistic UI only for reversible local actions. Publishing status must reflect server/provider confirmation, not merely the tap.

Empty state examples:
- Content: “Your content library is empty. Add a post or upload an asset.”
- Queue: “Nothing scheduled yet. Create a post to plan your next publish.”
- Accounts: “Connect an account or set up a manual publishing destination.”

## 7. Accessibility
- Meet WCAG AA contrast where applicable.
- Minimum comfortable touch target around 44–48 logical pixels.
- Support system text scaling.
- Provide semantic labels for account, status, and actions.
- Status must include text and icon, not color alone.
- Confirm destructive actions and clearly label irreversible publishing actions.

## 8. Content language
Use direct operational language:
- “Published to 3 of 4 accounts”
- “Instagram needs reconnection”
- “Manual publishing required”
- “Retry may create a duplicate”
Avoid vague terms such as “Oops,” “Magic,” or “Something went wrong” without useful detail.

## 9. Responsive behavior
- Mobile-first Flutter layouts.
- Use split-pane/side navigation only on wider screens if a web client is added.
- Composer should keep selected destinations visible while scrolling where practical.
- Calendar may switch to agenda/list mode on small screens.

## 10. Do not design yet
Do not overbuild analytics dashboards, team approval chains, AI assistants, drag-and-drop calendars, or a public marketing website before the publishing workflow is reliable.
