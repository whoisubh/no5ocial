# No5ocial — Shaadow Internal Social Publishing Manager

No5ocial is an internal-first Flutter app for managing content and publishing it to multiple social accounts from one workflow.

## Product principle
Create once, adapt per platform, select destinations, schedule where supported, publish, and track the result from one dashboard. Do not promise universal one-click publishing: each network has separate API access, account requirements, media rules, and costs.

## Suggested MVP
1. Content library for captions and media assets.
2. Brand and social-account registry.
3. Multi-destination composer with per-platform caption overrides.
4. Preflight validation and platform-specific previews.
5. Publishing queue with per-destination status, retries, and audit history.
6. Scheduler for integrations whose official APIs and permissions support it.
7. Manual-publishing handoff for unsupported, restricted, or uneconomical destinations.
8. Secure OAuth connections and token lifecycle management.

## Starter pack
- `PRD.md` — scope, user stories, acceptance criteria, roadmap.
- `DESIGN.md` — product UX and visual design system.
- `AGENTS.md` — coding-agent instructions and engineering guardrails.
- `ARCHITECTURE.md` — proposed system architecture.
- `INTEGRATIONS.md` — platform-by-platform integration plan.
- `SECURITY.md` — secrets, auth, and operational safety.
- `ROADMAP.md` — phased delivery and launch gates.
- `MASTER_BUILD_PROMPT.md` — long prompt for an AI coding agent.

## Recommended stack
Flutter client + a server-side API and worker. Supabase (Auth, Postgres, Storage, Edge Functions) is a reasonable prototype option, but keep provider-specific publishing behind a `PublishingAdapter` interface. Never put platform client secrets or long-lived tokens in the Flutter app.

## Start here
1. Read the PRD and integration constraints before coding.
2. Confirm which social accounts are Professional/Business/Creator and which API permissions can be obtained.
3. Build the content library and manual publishing workflow first.
4. Prove one official integration end-to-end before building a generalized scheduler.
5. Track cost per successful published destination; use manual fallback where API costs or access are unsuitable.
