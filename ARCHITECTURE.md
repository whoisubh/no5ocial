# Proposed Architecture

## Overview
Use Flutter as the client and a server-side publishing service as the authority for connections, scheduling, and provider API calls.

```text
Flutter app
  ├── Home / Content / Composer / Calendar / Accounts
  └── No5ocial API client
          |
Backend API + Auth
  ├── Brand and account registry
  ├── Content metadata + media storage
  ├── Scheduler / durable job queue
  ├── Publishing orchestrator
  ├── OAuth connection service
  └── Provider adapters
       ├── Instagram adapter
       ├── YouTube adapter
       ├── LinkedIn adapter
       └── X adapter (only after cost validation)
```

## Suggested prototype stack
- Client: Flutter, Dart, Material 3.
- Backend: Supabase Auth + Postgres + Storage + Edge Functions for a prototype, or a small dedicated API/worker if long-running media uploads and job processing exceed edge runtime limits.
- Queue: durable database-backed jobs with a worker; use a managed queue if retries/concurrency become complex.
- Secrets: server environment/secrets manager; never client bundle.
- Monitoring: structured server logs, error reporting, provider health and cost dashboard.

## Domain entities
- `Brand(id, name, slug, status, created_at)`
- `SocialAccount(id, brand_id, platform, display_name, handle, external_account_id, connection_status, capabilities, last_verified_at)`
- `OAuthConnection(id, provider, account_id, encrypted_access_token_ref, encrypted_refresh_token_ref, expires_at, scopes, status)`
- `ContentPost(id, brand_id, title, status, created_by, created_at, updated_at)`
- `MediaAsset(id, storage_key, mime_type, size_bytes, width, height, duration_ms, checksum, created_at)`
- `PostVariant(id, content_post_id, social_account_id, caption, media_asset_ids, first_comment, alt_text, metadata)`
- `PublishJob(id, post_variant_id, social_account_id, status, scheduled_at_utc, attempt_count, idempotency_key, external_post_id, external_url, last_error_code, last_error_at)`
- `PublishAttempt(id, publish_job_id, started_at, finished_at, outcome, sanitized_error, provider_request_id)`
- `AuditEvent(id, actor_id, event_type, entity_type, entity_id, created_at, metadata_sanitized)`

Adjust schema based on provider behavior; do not store provider tokens directly in ordinary content tables.

## Publishing adapter contract
Each adapter should expose capabilities and preflight separately from execution:
- `getCapabilities(account)`
- `validateDraft(account, variant)`
- `publishNow(account, variant, idempotencyContext)`
- `reconcileAmbiguousOutcome(account, attempt)`
- `refreshConnection(account)`
- `normalizeError(providerError)`

Represent capabilities explicitly, e.g. text, image, video, carousel, scheduled publish, post URL lookup, alt text. A capability is enabled only after official documentation and a working integration test confirm it.

## Scheduling and job states
Draft → Scheduled → Publishing → Published
Possible branches: Action Required, Failed, Cancelled.
- Store UTC; schedule worker wakes on due jobs.
- Acquire a lock/lease before processing to prevent two workers publishing the same job.
- Create a durable attempt record before calling a provider.
- If provider succeeds, store returned external ID and URL.
- If timeout occurs after request submission, mark outcome as ambiguous until reconciled; do not blindly repeat.
- Apply bounded retries to transient errors only.

## Media handling
- Upload media to private storage.
- Validate MIME type, file size, dimensions, aspect ratio, duration, and codec as required by each destination.
- Use provider-accessible media URLs or provider upload flows as required. Do not assume a private storage URL is fetchable by a provider.
- Keep originals; derive platform variants without destructive replacement.
- Clean up orphaned temporary files according to a documented retention policy.

## Environments
- `local`, `staging`, `production`.
- Separate OAuth apps/credentials where feasible.
- Separate storage buckets and database projects.
- Migrations must be repeatable and reviewed.
- Seed fake accounts only in local/staging; never label mock publishing as real.

## Cost controls
- Log provider calls and estimated API cost per destination.
- Alert on abnormal retries and upload failures.
- Provide a manual handoff option if a platform's API cost exceeds the configured budget.
