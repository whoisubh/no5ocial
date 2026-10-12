-- ==============================================================================
-- no5ocial Seed Data (Shaadow Brands & Accounts)
-- For local and staging environments
-- ==============================================================================

-- 1. Insert Brands
INSERT INTO brands (id, name, slug, status)
VALUES
    ('b1000000-0000-0000-0000-000000000001', 'Shaadow', 'shaadow', 'active'),
    ('b1000000-0000-0000-0000-000000000002', 'Shaadow Works', 'shaadow-works', 'active'),
    ('b1000000-0000-0000-0000-000000000003', 'Boofer', 'boofer', 'active'),
    ('b1000000-0000-0000-0000-000000000004', 'Favtunes', 'favtunes', 'active'),
    ('b1000000-0000-0000-0000-000000000005', 'Galaxious', 'galaxious', 'active'),
    ('b1000000-0000-0000-0000-000000000006', 'Owl & Fowl Studios', 'owl-and-fowl-studios', 'active')
ON CONFLICT (slug) DO NOTHING;

-- 2. Insert Social Accounts
INSERT INTO social_accounts (id, brand_id, platform, display_name, handle, external_account_id, connection_status, capabilities, last_verified_at)
VALUES
    -- Shaadow Accounts
    ('a1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'instagram', 'Shaadow Instagram', '@shaadow.official', 'ig_act_001', 'connected', 
     '{"text": false, "image": true, "video": true, "carousel": true, "maxChars": 2200, "maxHashtags": 30, "requiresMedia": true, "scheduledPublish": true}'::jsonb, 
     timezone('utc', now())),
     
    ('a1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000001', 'youtube', 'Shaadow YouTube', '@ShaadowOfficial', 'yt_act_001', 'connected', 
     '{"text": false, "image": false, "video": true, "carousel": false, "maxChars": 5000, "requiresMedia": true, "scheduledPublish": true}'::jsonb, 
     timezone('utc', now())),

    ('a1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000001', 'linkedin', 'Shaadow Platforms', 'Shaadow Platforms', 'li_org_001', 'connected', 
     '{"text": true, "image": true, "video": true, "carousel": false, "maxChars": 3000, "requiresMedia": false, "scheduledPublish": false}'::jsonb, 
     timezone('utc', now())),

    ('a1000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000001', 'x', 'Shaadow X', '@shaadow', 'x_act_001', 'connected', 
     '{"text": true, "image": true, "video": true, "carousel": false, "maxChars": 280, "requiresMedia": false, "scheduledPublish": false}'::jsonb, 
     timezone('utc', now())),

    -- Shaadow Works
    ('a1000000-0000-0000-0000-000000000005', 'b1000000-0000-0000-0000-000000000002', 'instagram', 'Shaadow Works Instagram', '@shaadowworks', 'ig_act_002', 'connected', 
     '{"text": false, "image": true, "video": true, "carousel": true, "maxChars": 2200, "maxHashtags": 30, "requiresMedia": true, "scheduledPublish": true}'::jsonb, 
     timezone('utc', now())),

    -- Boofer
    ('a1000000-0000-0000-0000-000000000006', 'b1000000-0000-0000-0000-000000000003', 'instagram', 'Boofer Instagram', '@boofer.world', 'ig_act_003', 'connected', 
     '{"text": false, "image": true, "video": true, "carousel": true, "maxChars": 2200, "maxHashtags": 30, "requiresMedia": true, "scheduledPublish": true}'::jsonb, 
     timezone('utc', now())),

    ('a1000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000003', 'x', 'Boofer X', '@boofer', 'x_act_002', 'connected', 
     '{"text": true, "image": true, "video": true, "carousel": false, "maxChars": 280, "requiresMedia": false, "scheduledPublish": false}'::jsonb, 
     timezone('utc', now())),

    -- Owl & Fowl Studios
    ('a1000000-0000-0000-0000-000000000008', 'b1000000-0000-0000-0000-000000000006', 'instagram', 'Owl & Fowl Instagram', '@owlandfowlstudios', 'ig_act_004', 'connected', 
     '{"text": false, "image": true, "video": true, "carousel": true, "maxChars": 2200, "maxHashtags": 30, "requiresMedia": true, "scheduledPublish": true}'::jsonb, 
     timezone('utc', now())),

    ('a1000000-0000-0000-0000-000000000009', 'b1000000-0000-0000-0000-000000000006', 'youtube', 'Owl & Fowl YouTube', '@OwlAndFowlStudios', 'yt_act_002', 'connected', 
     '{"text": false, "image": false, "video": true, "carousel": false, "maxChars": 5000, "requiresMedia": true, "scheduledPublish": true}'::jsonb, 
     timezone('utc', now()))
ON CONFLICT (id) DO NOTHING;

-- 3. Insert Initial Audit Event
INSERT INTO audit_events (actor_id, event_type, entity_type, entity_id, metadata_sanitized)
VALUES (
    'system',
    'system_seeded',
    'system',
    'initial_setup',
    '{"message": "no5ocial initial portfolio seeded successfully", "brandCount": 6, "accountCount": 9}'::jsonb
);
