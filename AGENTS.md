# AGENTS.md — Instructions for AI Coding Agents

## Mission
Build no5ocial as a secure, reliable internal publishing workflow for Shaadow. Optimize for correctness, clear failure states, and low operating cost—not for feature count.

## Mandatory behavior
1. Read `README.md`, `PRD.md`, `DESIGN.md`, `ARCHITECTURE.md`, `INTEGRATIONS.md`, and `SECURITY.md` before major implementation.
2. Implement the smallest complete vertical slice; do not scaffold every feature with fake data and call it done.
3. Never claim a social API integration works unless it has been tested against the official API with authorized credentials.
4. Keep platform publishing behind interfaces/adapters. UI must not contain provider-specific HTTP logic.
5. Do not store provider access tokens, refresh tokens, client secrets, or service-role keys in Flutter assets, source, local preferences, analytics, or logs.
6. Do not implement browser automation, scraping, reverse-engineered endpoints, or credential collection.
7. Do not fabricate API capabilities. When a platform cannot be published to, implement manual handoff with clear status.
8. For a multi-destination publish, track each destination independently.
9. Treat timeouts after a publish request as ambiguous outcomes. Query/reconcile if supported; otherwise warn before retrying to avoid duplicates.
10. Add tests for business logic and failure paths alongside implementation.
11. **Mandatory Real Authentication Only**: Google Sign-In is strictly mandatory. Login is NEVER optional. NEVER add "Enter offline workspace", "Dev workspace sign-in", "Skip login", demo bypass buttons, or hardcoded dummy profiles (`admin@shaadow.io`, `Workspace Lead`, etc.) anywhere in the UI, dialogs, or error handlers.
12. **Active Auth Guards Everywhere**: The dashboard shell (`MainScaffold`), `HomeScreen`, and all internal endpoints must enforce active authentication on every render. If `!appState.isLoggedIn`, unauthenticated sessions must be immediately rejected and redirected to the root auth screen.
13. **Strict Error Handling**: When authentication fails (e.g. missing Android SHA-1 in Google Cloud Console), report the exact error honestly with a Dismiss button only. NEVER provide a bypass button to circumvent failed authentication.

## Architecture rules
- Flutter presentation layer → application/use-case layer → domain models/interfaces → repository implementations.
- Platform adapters are server-side. Flutter calls the no5ocial backend only.
- Use typed models and explicit status enums; avoid free-form status strings.
- Keep provider-specific IDs and errors in adapter/repository boundaries.
- Persist all timestamps as UTC; render in configured timezone.
- Never run scheduled publication solely from a mobile timer or background task.
- Use database migrations for schema changes.
- Use environment variables/secrets manager for server configuration.
- Use dependency injection; avoid global singletons except carefully documented infrastructure.

## Code quality
- Follow effective Dart and Flutter linting.
- Use null safety; avoid `dynamic` unless boundary parsing requires it.
- Keep widgets focused and small.
- Handle loading/empty/error states.
- Avoid dead code, unreferenced packages, and speculative abstractions.
- Do not add a dependency without explaining why it is needed.
- Format and analyze before completing work.
- Never swallow exceptions silently.

## Security and privacy
- Validate all backend inputs and uploaded file types/sizes.
- Apply authorization on every backend query and storage operation.
- Use least-privilege OAuth scopes.
- Redact tokens, authorization headers, and sensitive provider payloads from logs.
- Protect OAuth state and verify callback state.
- Use short-lived signed media URLs where needed.
- Keep audit events useful but avoid storing unnecessary personal data.
- Follow `SECURITY.md`.

## Publishing rules
- Preflight each destination before enqueueing.
- Use idempotency keys internally for jobs; understand that internal idempotency cannot guarantee provider-side deduplication unless the provider supports it.
- Apply exponential backoff with jitter only to retryable failures.
- Do not retry authentication, permission, validation, or policy errors automatically.
- Rate-limit per provider/account.
- Store external post ID and URL when returned.
- Record attempts, timestamps, and a sanitized error category.
- One provider failure must not roll back other successful destination jobs.

## Definition of done
A change is done only when:
- It meets a PRD acceptance criterion.
- It includes appropriate tests.
- Loading, empty, success, and error states are addressed.
- Security implications have been considered.
- Documentation/config examples are updated.
- `flutter analyze` and relevant tests pass, or any failure is reported honestly.
- No secrets or fake production integrations are committed.

## Collaboration style
Before a large change, state the plan briefly and identify unresolved API constraints. Ask questions only when a decision blocks safe implementation; otherwise choose conservative defaults and document assumptions. Do not rewrite unrelated files. Prefer incremental commits and explain trade-offs.
