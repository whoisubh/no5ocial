# Security and Operational Safety

## Secrets and OAuth
- Never embed client secrets, service-role keys, access tokens, or refresh tokens in Flutter source or app assets.
- Keep OAuth code exchange and refresh operations server-side.
- Validate OAuth `state` and use PKCE when supported/appropriate.
- Encrypt refresh tokens at rest using managed key infrastructure; restrict access to the publishing service.
- Request least-privilege scopes and explain each requested permission.
- Provide disconnect/revoke workflows and remove stored credentials when appropriate.

## Authorization
- Every backend request must verify the authenticated user and resource permissions.
- Enforce database row-level security where supported.
- Storage buckets must not be public by default.
- Use signed URLs with short expirations for private media.
- Protect against account mix-ups: destination account identity must be visible before publishing.

## Content and uploads
- Validate MIME type, extension, size, dimensions, duration, and media decode.
- Do not trust client-provided content type alone.
- Apply upload limits and rate limits.
- Prevent arbitrary URL fetches (SSRF) in server-side media handling.
- Keep platform-specific transformations auditable.

## Publishing safety
- Require explicit user action to publish immediately.
- For scheduled posts, show target accounts, time, and timezone before confirmation.
- Do not silently republish after an ambiguous timeout.
- Use a durable audit trail for publish, retry, cancel, disconnect, and manual confirmation actions.
- Never log Authorization headers, OAuth codes, tokens, or raw secrets.
- Sanitize provider errors and redact sensitive IDs where appropriate.

## Reliability
- Use bounded retries with exponential backoff and jitter.
- Do not retry permission, policy, validation, or authentication errors until corrected.
- Apply per-account/provider concurrency limits.
- Add a budget guard for usage-priced APIs.
- Provide a kill switch to pause publishing jobs globally or per provider.

## Compliance
- Use only official platform APIs and documented permissions.
- Review each provider's developer terms and platform content policies before release.
- Build deletion/disconnection flows and document retention periods.
- Do not claim legal or policy compliance without an actual review.
