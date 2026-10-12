-- ==============================================================================
-- no5ocial Database Schema (PostgreSQL / Supabase)
-- Designed per ARCHITECTURE.md, SECURITY.md, and PRD.md
-- 
-- Principles:
-- 1. All timestamps are explicitly UTC (TIMESTAMPTZ stored and indexed).
-- 2. Sensitive OAuth tokens reside only in oauth_connections with encryption references.
-- 3. Publish jobs have unique idempotency keys and independent status per destination.
-- 4. Audit events store only sanitized metadata.
-- 5. Row Level Security (RLS) enabled on all tables.
-- ==============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Helper trigger function for updating updated_at timestamp
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc', now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------------------------
-- 1. Brands Table
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS brands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'archived', 'suspended')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE TRIGGER trg_brands_updated_at
BEFORE UPDATE ON brands
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ------------------------------------------------------------------------------
-- 2. Social Accounts Table
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS social_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE RESTRICT,
    platform VARCHAR(30) NOT NULL CHECK (platform IN ('instagram', 'youtube', 'linkedin', 'x', 'facebook', 'tiktok', 'threads')),
    display_name VARCHAR(150) NOT NULL,
    handle VARCHAR(100) NOT NULL,
    external_account_id VARCHAR(255),
    connection_status VARCHAR(30) NOT NULL DEFAULT 'connected' CHECK (connection_status IN ('connected', 'expired', 'revoked', 'disconnected', 'error')),
    capabilities JSONB NOT NULL DEFAULT '{"text": true, "image": false, "video": false, "scheduledPublish": false}'::jsonb,
    last_verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_social_accounts_brand_id ON social_accounts(brand_id);
CREATE INDEX IF NOT EXISTS idx_social_accounts_platform ON social_accounts(platform);

CREATE TRIGGER trg_social_accounts_updated_at
BEFORE UPDATE ON social_accounts
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ------------------------------------------------------------------------------
-- 3. OAuth Connections (Sensitive Credentials Vault References)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS oauth_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    social_account_id UUID NOT NULL REFERENCES social_accounts(id) ON DELETE CASCADE,
    provider VARCHAR(30) NOT NULL,
    -- Encrypted vault reference or KMS ciphertext key pointer — NEVER raw plaintext tokens!
    encrypted_access_token_ref TEXT NOT NULL,
    encrypted_refresh_token_ref TEXT,
    expires_at TIMESTAMPTZ,
    scopes TEXT[] NOT NULL DEFAULT '{}',
    status VARCHAR(30) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'revoked')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_oauth_connections_account ON oauth_connections(social_account_id);

CREATE TRIGGER trg_oauth_connections_updated_at
BEFORE UPDATE ON oauth_connections
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ------------------------------------------------------------------------------
-- 4. Media Assets Table
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS media_assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    storage_key TEXT NOT NULL UNIQUE,
    mime_type VARCHAR(100) NOT NULL,
    size_bytes BIGINT NOT NULL CHECK (size_bytes > 0),
    width INT,
    height INT,
    duration_ms INT,
    checksum VARCHAR(128) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_media_assets_storage_key ON media_assets(storage_key);

-- ------------------------------------------------------------------------------
-- 5. Content Posts Table (Master Canonical Posts)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS content_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE RESTRICT,
    title VARCHAR(255) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'publishing', 'published', 'partial_failure', 'action_required', 'failed', 'cancelled')),
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_content_posts_brand_status ON content_posts(brand_id, status);
CREATE INDEX IF NOT EXISTS idx_content_posts_created_at ON content_posts(created_at DESC);

CREATE TRIGGER trg_content_posts_updated_at
BEFORE UPDATE ON content_posts
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ------------------------------------------------------------------------------
-- 6. Post Variants Table (Per-Destination Overrides)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS post_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_post_id UUID NOT NULL REFERENCES content_posts(id) ON DELETE CASCADE,
    social_account_id UUID NOT NULL REFERENCES social_accounts(id) ON DELETE RESTRICT,
    caption TEXT NOT NULL DEFAULT '',
    media_asset_ids UUID[] NOT NULL DEFAULT '{}',
    first_comment TEXT,
    alt_text TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_post_variants_post_id ON post_variants(content_post_id);
CREATE INDEX IF NOT EXISTS idx_post_variants_account_id ON post_variants(social_account_id);

-- ------------------------------------------------------------------------------
-- 7. Publish Jobs Table (Independent Destination Execution)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS publish_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_variant_id UUID NOT NULL REFERENCES post_variants(id) ON DELETE CASCADE,
    social_account_id UUID NOT NULL REFERENCES social_accounts(id) ON DELETE RESTRICT,
    status VARCHAR(30) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'scheduled', 'publishing', 'published', 'failed', 'manual_pending', 'action_required', 'cancelled')),
    scheduled_at_utc TIMESTAMPTZ,
    attempt_count INT NOT NULL DEFAULT 0,
    idempotency_key VARCHAR(128) NOT NULL UNIQUE,
    is_manual BOOLEAN NOT NULL DEFAULT FALSE,
    external_post_id VARCHAR(255),
    external_url TEXT,
    last_error_code VARCHAR(100),
    last_error_at TIMESTAMPTZ,
    requires_duplicate_confirmation BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- Durable queue index for scheduler worker polling
CREATE INDEX IF NOT EXISTS idx_publish_jobs_queue 
ON publish_jobs (status, scheduled_at_utc) 
WHERE status IN ('scheduled', 'pending');

CREATE INDEX IF NOT EXISTS idx_publish_jobs_account_id ON publish_jobs(social_account_id);

CREATE TRIGGER trg_publish_jobs_updated_at
BEFORE UPDATE ON publish_jobs
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ------------------------------------------------------------------------------
-- 8. Publish Attempts Table (Execution History and Audit)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS publish_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    publish_job_id UUID NOT NULL REFERENCES publish_jobs(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    finished_at TIMESTAMPTZ,
    outcome VARCHAR(30) NOT NULL CHECK (outcome IN ('success', 'failed', 'ambiguous_timeout', 'manual_confirmed')),
    sanitized_error TEXT,
    provider_request_id VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS idx_publish_attempts_job_id ON publish_attempts(publish_job_id);

-- ------------------------------------------------------------------------------
-- 9. Audit Events Table
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id VARCHAR(100) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    -- Sanitized metadata strictly without bearer tokens or user credentials
    metadata_sanitized JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_audit_events_created_at ON audit_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_events_entity ON audit_events(entity_type, entity_id);

-- ------------------------------------------------------------------------------
-- 10. Row Level Security (RLS) Configuration
-- ------------------------------------------------------------------------------
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE oauth_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE media_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE publish_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE publish_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_events ENABLE ROW LEVEL SECURITY;

-- Standard internal authenticated user policies (adjust based on user roles in Supabase)
CREATE POLICY "Allow authenticated users full access to brands" 
ON brands FOR ALL TO authenticated USING (true);

CREATE POLICY "Allow authenticated users full access to social_accounts" 
ON social_accounts FOR ALL TO authenticated USING (true);

-- oauth_connections restricted: only publishing service role should access tokens directly
CREATE POLICY "Restrict oauth_connections to service role" 
ON oauth_connections FOR ALL TO service_role USING (true);

CREATE POLICY "Allow authenticated users full access to content_posts" 
ON content_posts FOR ALL TO authenticated USING (true);

CREATE POLICY "Allow authenticated users full access to post_variants" 
ON post_variants FOR ALL TO authenticated USING (true);

CREATE POLICY "Allow authenticated users full access to publish_jobs" 
ON publish_jobs FOR ALL TO authenticated USING (true);

CREATE POLICY "Allow authenticated users full access to publish_attempts" 
ON publish_attempts FOR ALL TO authenticated USING (true);

CREATE POLICY "Allow authenticated users full access to audit_events" 
ON audit_events FOR ALL TO authenticated USING (true);
