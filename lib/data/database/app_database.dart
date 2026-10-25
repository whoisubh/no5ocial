import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:no5ocial/data/local/seed_data.dart';
import 'package:no5ocial/domain/enums/connection_status.dart';
import 'package:no5ocial/domain/enums/error_category.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/enums/publish_status.dart';
import 'package:no5ocial/domain/models/audit_event.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/channel_group.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/publish_job.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/domain/models/org_member.dart';
import 'package:no5ocial/domain/models/org_invite.dart';
import 'package:no5ocial/domain/models/monetization/monetization_models.dart';

class AppDatabase {
  static AppDatabase? _instance;
  Database? _db;

  AppDatabase._();

  static AppDatabase get instance => _instance ??= AppDatabase._();

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    if (kIsWeb) {
      try {
        return await _openWithFactory(databaseFactoryFfiWeb, 'no5ocial.db');
      } catch (e) {
        debugPrint('Web worker init failed, fallback to databaseFactoryFfiWebNoWebWorker: $e');
        return await _openWithFactory(databaseFactoryFfiWebNoWebWorker, 'no5ocial.db');
      }
    } else if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      final databasesPath = await sqflite.getDatabasesPath();
      final path = '$databasesPath/no5ocial.db';
      return await _openWithFactory(sqflite.databaseFactory, path);
    } else {
      try {
        sqfliteFfiInit();
      } catch (_) {}
      return await _openWithFactory(databaseFactoryFfi, 'no5ocial.db');
    }
  }

  Future<Database> _openWithFactory(DatabaseFactory factory, String path) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await _createTables(db);
        },
      ),
    );

    // Ensure tables exist
    await _createTables(db);

    return db;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('brands');
    await db.delete('channel_groups');
    await db.delete('social_accounts');
    await db.delete('content_posts');
    await db.delete('post_variants');
    await db.delete('media_assets');
    await db.delete('publish_jobs');
    await db.delete('audit_events');
    await db.delete('user_profiles');
    await db.delete('org_members');
    await db.delete('org_invites');
    await db.delete('user_wallets');
    await db.delete('coin_transactions');
    await db.delete('publishing_passes');
  }

  /// Clears only temporary media assets and draft caches on the local device,
  /// preserving user accounts, authentication session, linked channels, brands, and wallets.
  Future<int> clearTemporaryCache() async {
    final db = await database;
    // Remove local cached media assets
    final mediaCount = await db.delete('media_assets');
    // Remove drafts that have not been published
    final draftCount = await db.delete('content_posts', where: "status = 'draft'");
    return mediaCount + draftCount;
  }

  Future<void> seedDemoData() async {
    final db = await database;
    await _seedInitialData(db);
  }

  Future<void> removeSeedDemoData() async {
    final db = await database;
    const seedBrandIds = [
      'brand-shaadow',
      'brand-shaadow-works',
      'brand-boofer',
      'brand-favtunes',
      'brand-galaxious',
      'brand-owl-and-fowl',
    ];
    for (final bId in seedBrandIds) {
      await db.delete('brands', where: 'id = ?', whereArgs: [bId]);
      await db.delete('social_accounts', where: 'brand_id = ?', whereArgs: [bId]);
      await db.delete('channel_groups', where: 'brand_id = ?', whereArgs: [bId]);
      await db.delete('content_posts', where: 'brand_id = ?', whereArgs: [bId]);
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS brands (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        slug TEXT NOT NULL,
        description TEXT,
        website_url TEXT,
        company_size TEXT,
        industry TEXT,
        found_us_via TEXT,
        is_active INTEGER NOT NULL,
        created_at_utc TEXT NOT NULL
      )
    ''');

    // Run schema migrations safely if upgrading from an older schema version
    final columns = await db.rawQuery('PRAGMA table_info(brands)');
    final columnNames = columns.map((c) => c['name'] as String).toSet();
    if (!columnNames.contains('company_size')) {
      await db.execute('ALTER TABLE brands ADD COLUMN company_size TEXT');
    }
    if (!columnNames.contains('industry')) {
      await db.execute('ALTER TABLE brands ADD COLUMN industry TEXT');
    }
    if (!columnNames.contains('found_us_via')) {
      await db.execute('ALTER TABLE brands ADD COLUMN found_us_via TEXT');
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS channel_groups (
        id TEXT PRIMARY KEY,
        brand_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        account_ids TEXT NOT NULL,
        created_at_utc TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS social_accounts (
        id TEXT PRIMARY KEY,
        brand_id TEXT NOT NULL,
        platform TEXT NOT NULL,
        display_name TEXT NOT NULL,
        handle TEXT NOT NULL,
        external_account_id TEXT,
        connection_status TEXT NOT NULL,
        capabilities TEXT NOT NULL,
        scopes TEXT NOT NULL,
        last_verified_at_utc TEXT,
        is_manual_only INTEGER NOT NULL,
        created_at_utc TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS content_posts (
        id TEXT PRIMARY KEY,
        brand_id TEXT NOT NULL,
        group_id TEXT,
        title TEXT NOT NULL,
        default_caption TEXT NOT NULL,
        destination_account_ids TEXT NOT NULL,
        media_asset_ids TEXT NOT NULL,
        campaign TEXT,
        tags TEXT NOT NULL,
        status TEXT NOT NULL,
        scheduled_at_utc TEXT,
        created_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS post_variants (
        id TEXT PRIMARY KEY,
        content_post_id TEXT NOT NULL,
        social_account_id TEXT NOT NULL,
        caption_override TEXT,
        media_asset_ids TEXT,
        first_comment TEXT,
        alt_text TEXT,
        privacy_status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS media_assets (
        id TEXT PRIMARY KEY,
        file_name TEXT NOT NULL,
        mime_type TEXT NOT NULL,
        size_bytes INTEGER NOT NULL,
        width INTEGER,
        height INTEGER,
        duration_ms INTEGER,
        checksum TEXT,
        local_preview_url TEXT,
        media_type TEXT NOT NULL,
        created_at_utc TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS publish_jobs (
        id TEXT PRIMARY KEY,
        content_post_id TEXT NOT NULL,
        post_variant_id TEXT NOT NULL,
        social_account_id TEXT NOT NULL,
        idempotency_key TEXT NOT NULL,
        status TEXT NOT NULL,
        is_manual INTEGER NOT NULL,
        attempt_count INTEGER NOT NULL,
        scheduled_at_utc TEXT,
        published_at_utc TEXT,
        external_post_id TEXT,
        external_url TEXT,
        last_error_code TEXT,
        last_error_category TEXT,
        last_error_message TEXT,
        last_error_at_utc TEXT,
        created_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_events (
        id TEXT PRIMARY KEY,
        actor TEXT NOT NULL,
        event_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        description TEXT NOT NULL,
        metadata_json TEXT,
        created_at_utc TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        photo_url TEXT,
        provider TEXT NOT NULL,
        access_token TEXT,
        id_token TEXT,
        server_auth_code TEXT,
        raw_data TEXT,
        created_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS org_members (
        id TEXT PRIMARY KEY,
        org_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_email TEXT NOT NULL,
        user_name TEXT NOT NULL,
        user_photo_url TEXT,
        role TEXT NOT NULL,
        brand_scope TEXT,
        invited_by_user_id TEXT,
        joined_at_utc TEXT NOT NULL,
        is_active INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS org_invites (
        id TEXT PRIMARY KEY,
        org_id TEXT NOT NULL,
        token TEXT NOT NULL,
        invited_email TEXT NOT NULL,
        invited_role TEXT NOT NULL,
        brand_scope TEXT,
        invited_by_user_id TEXT NOT NULL,
        created_at_utc TEXT NOT NULL,
        expires_at_utc TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_wallets (
        user_id TEXT PRIMARY KEY,
        balance INTEGER NOT NULL DEFAULT 0,
        total_earned INTEGER NOT NULL DEFAULT 0,
        total_spent INTEGER NOT NULL DEFAULT 0,
        created_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL,
        synced_at_utc TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS coin_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        amount INTEGER NOT NULL,
        balance_after INTEGER NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        reference_id TEXT,
        created_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL,
        synced_at_utc TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS publishing_passes (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        cost_coins INTEGER NOT NULL DEFAULT 10,
        max_posts INTEGER NOT NULL DEFAULT 2,
        posts_used INTEGER NOT NULL DEFAULT 0,
        duration_days INTEGER NOT NULL DEFAULT 2,
        activated_at_utc TEXT NOT NULL,
        expires_at_utc TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL,
        synced_at_utc TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anti_abuse_tombstones (
        identity_hash TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        device_id TEXT,
        deleted_at_utc TEXT NOT NULL,
        lifetime_coins_exhausted INTEGER NOT NULL DEFAULT 1,
        metadata_json TEXT
      )
    ''');

    // Run schema migrations safely to add sync tracking metadata columns
    await _ensureSyncColumns(db, 'brands');
    await _ensureSyncColumns(db, 'channel_groups');
    await _ensureSyncColumns(db, 'social_accounts');
    await _ensureSyncColumns(db, 'content_posts');
    await _ensureSyncColumns(db, 'post_variants');
    await _ensureSyncColumns(db, 'publish_jobs');
    await _ensureSyncColumns(db, 'media_assets');
    await _ensureSyncColumns(db, 'audit_events');
    await _ensureSyncColumns(db, 'org_members');
    await _ensureSyncColumns(db, 'org_invites');
    await _ensureSyncColumns(db, 'user_wallets');
    await _ensureSyncColumns(db, 'coin_transactions');
    await _ensureSyncColumns(db, 'publishing_passes');
  }

  Future<void> _ensureSyncColumns(Database db, String tableName) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final columnNames = columns.map((c) => c['name'] as String).toSet();
    if (!columnNames.contains('updated_at_utc')) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN updated_at_utc TEXT');
    }
    if (!columnNames.contains('synced_at_utc')) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN synced_at_utc TEXT');
    }
    if (!columnNames.contains('is_deleted')) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0');
    }
  }

  Future<void> _seedInitialData(Database db) async {
    final batch = db.batch();

    // 1. Brands
    for (final b in SeedData.initialBrands) {
      batch.insert('brands', {
        'id': b.id,
        'name': b.name,
        'slug': b.slug,
        'description': b.description,
        'website_url': b.websiteUrl,
        'is_active': b.isActive ? 1 : 0,
        'created_at_utc': b.createdAtUtc.toIso8601String(),
      });
    }

    // 2. Channel Groups
    for (final g in SeedData.initialGroups) {
      batch.insert('channel_groups', g.toMap());
    }

    // 3. Social Accounts
    for (final a in SeedData.initialAccounts) {
      batch.insert('social_accounts', {
        'id': a.id,
        'brand_id': a.brandId,
        'platform': a.platform.name,
        'display_name': a.displayName,
        'handle': a.handle,
        'external_account_id': a.externalAccountId,
        'connection_status': a.connectionStatus.name,
        'capabilities': jsonEncode(a.capabilities),
        'scopes': jsonEncode(a.scopes),
        'last_verified_at_utc': a.lastVerifiedAtUtc?.toIso8601String(),
        'is_manual_only': a.isManualOnly ? 1 : 0,
        'created_at_utc': DateTime.utc(2026, 1, 1).toIso8601String(),
      });
    }

    // 4. Media Assets
    for (final m in SeedData.initialMediaAssets) {
      batch.insert('media_assets', {
        'id': m.id,
        'file_name': m.fileName,
        'mime_type': m.mimeType,
        'size_bytes': m.sizeBytes,
        'width': m.width,
        'height': m.height,
        'duration_ms': m.durationMs,
        'checksum': m.checksum,
        'local_preview_url': m.localPreviewUrl,
        'media_type': m.mediaType.name,
        'created_at_utc': m.createdAtUtc.toIso8601String(),
      });
    }

    // 5. Content Posts
    for (final p in SeedData.initialPosts) {
      batch.insert('content_posts', {
        'id': p.id,
        'brand_id': p.brandId,
        'group_id': null,
        'title': p.title,
        'default_caption': p.defaultCaption,
        'destination_account_ids': jsonEncode(p.destinationAccountIds),
        'media_asset_ids': jsonEncode(p.mediaAssetIds),
        'campaign': p.campaign,
        'tags': jsonEncode(p.tags),
        'status': p.status.name,
        'scheduled_at_utc': p.scheduledAtUtc?.toIso8601String(),
        'created_at_utc': p.createdAtUtc.toIso8601String(),
        'updated_at_utc': p.updatedAtUtc.toIso8601String(),
      });
    }

    // 6. Post Variants
    for (final v in SeedData.initialVariants) {
      batch.insert('post_variants', {
        'id': v.id,
        'content_post_id': v.contentPostId,
        'social_account_id': v.socialAccountId,
        'caption_override': v.captionOverride,
        'media_asset_ids': jsonEncode(v.mediaAssetIds),
        'first_comment': v.firstComment,
        'alt_text': v.altText,
        'privacy_status': v.privacyStatus.name,
      });
    }

    // 7. Publish Jobs
    for (final j in SeedData.initialJobs) {
      batch.insert('publish_jobs', {
        'id': j.id,
        'content_post_id': j.contentPostId,
        'post_variant_id': j.postVariantId,
        'social_account_id': j.socialAccountId,
        'idempotency_key': j.idempotencyKey,
        'status': j.status.name,
        'is_manual': j.isManual ? 1 : 0,
        'attempt_count': j.attemptCount,
        'scheduled_at_utc': j.scheduledAtUtc?.toIso8601String(),
        'published_at_utc': j.publishedAtUtc?.toIso8601String(),
        'external_post_id': j.externalPostId,
        'external_url': j.externalUrl,
        'last_error_code': j.lastErrorCode,
        'last_error_category': j.lastErrorCategory?.name,
        'last_error_message': j.lastErrorMessage,
        'last_error_at_utc': j.lastErrorAtUtc?.toIso8601String(),
        'created_at_utc': j.createdAtUtc.toIso8601String(),
        'updated_at_utc': j.updatedAtUtc.toIso8601String(),
      });
    }

    await batch.commit(noResult: true);
  }

  // --- Brand Operations ---
  Future<List<Brand>> getAllBrands() async {
    final db = await database;
    final maps = await db.query('brands', orderBy: 'name ASC');
    return maps.map((m) => Brand(
      id: m['id'] as String,
      name: m['name'] as String,
      slug: m['slug'] as String,
      description: m['description'] as String?,
      websiteUrl: m['website_url'] as String?,
      companySize: m['company_size'] as String?,
      industry: m['industry'] as String?,
      foundUsVia: m['found_us_via'] as String?,
      isActive: (m['is_active'] as int? ?? 1) == 1,
      createdAtUtc: DateTime.tryParse(m['created_at_utc'] as String? ?? '') ?? DateTime.now().toUtc(),
    )).toList();
  }

  Future<Brand?> getBrand(String id) async {
    final db = await database;
    final maps = await db.query('brands', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    final m = maps.first;
    return Brand(
      id: m['id'] as String,
      name: m['name'] as String,
      slug: m['slug'] as String,
      description: m['description'] as String?,
      websiteUrl: m['website_url'] as String?,
      companySize: m['company_size'] as String?,
      industry: m['industry'] as String?,
      foundUsVia: m['found_us_via'] as String?,
      isActive: (m['is_active'] as int? ?? 1) == 1,
      createdAtUtc: DateTime.tryParse(m['created_at_utc'] as String? ?? '') ?? DateTime.now().toUtc(),
    );
  }

  Future<void> saveBrand(Brand brand) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(
      'brands',
      {
        'id': brand.id,
        'name': brand.name,
        'slug': brand.slug,
        'description': brand.description,
        'website_url': brand.websiteUrl,
        'company_size': brand.companySize,
        'industry': brand.industry,
        'found_us_via': brand.foundUsVia,
        'is_active': brand.isActive ? 1 : 0,
        'created_at_utc': brand.createdAtUtc.toIso8601String(),
        'updated_at_utc': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBrand(String id) async {
    final db = await database;
    await db.delete('brands', where: 'id = ?', whereArgs: [id]);
    await db.delete('social_accounts', where: 'brand_id = ?', whereArgs: [id]);
    await db.delete('channel_groups', where: 'brand_id = ?', whereArgs: [id]);
  }

  // --- Channel Group Operations ---
  Future<List<ChannelGroup>> getAllGroups() async {
    final db = await database;
    final maps = await db.query('channel_groups', orderBy: 'name ASC');
    return maps.map((m) => ChannelGroup.fromMap(m)).toList();
  }

  Future<void> saveGroup(ChannelGroup group) async {
    final db = await database;
    final map = group.toMap();
    map['updated_at_utc'] = DateTime.now().toUtc().toIso8601String();
    await db.insert(
      'channel_groups',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteGroup(String id) async {
    final db = await database;
    await db.delete('channel_groups', where: 'id = ?', whereArgs: [id]);
  }

  // --- Social Account Operations ---
  Future<List<SocialAccount>> getAllAccounts() async {
    final db = await database;
    final maps = await db.query('social_accounts', orderBy: 'display_name ASC');
    return maps.map((m) {
      List<String> caps = [];
      if (m['capabilities'] != null) {
        try {
          final dec = jsonDecode(m['capabilities'] as String);
          if (dec is List) caps = dec.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      List<String> scs = [];
      if (m['scopes'] != null) {
        try {
          final dec = jsonDecode(m['scopes'] as String);
          if (dec is List) scs = dec.map((e) => e.toString()).toList();
        } catch (_) {}
      }

      PlatformType platform = PlatformType.instagram;
      try {
        platform = PlatformType.values.byName(m['platform'] as String);
      } catch (_) {}

      ConnectionStatus status = ConnectionStatus.connected;
      try {
        status = ConnectionStatus.values.byName(m['connection_status'] as String);
      } catch (_) {}

      return SocialAccount(
        id: m['id'] as String,
        brandId: m['brand_id'] as String,
        platform: platform,
        displayName: m['display_name'] as String,
        handle: m['handle'] as String,
        externalAccountId: m['external_account_id'] as String?,
        connectionStatus: status,
        capabilities: caps,
        scopes: scs,
        lastVerifiedAtUtc: m['last_verified_at_utc'] != null
            ? DateTime.tryParse(m['last_verified_at_utc'] as String)
            : null,
        isManualOnly: (m['is_manual_only'] as int? ?? 0) == 1,
      );
    }).toList();
  }

  Future<void> saveAccount(SocialAccount account) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(
      'social_accounts',
      {
        'id': account.id,
        'brand_id': account.brandId,
        'platform': account.platform.name,
        'display_name': account.displayName,
        'handle': account.handle,
        'external_account_id': account.externalAccountId,
        'connection_status': account.connectionStatus.name,
        'capabilities': jsonEncode(account.capabilities),
        'scopes': jsonEncode(account.scopes),
        'last_verified_at_utc': account.lastVerifiedAtUtc?.toIso8601String(),
        'is_manual_only': account.isManualOnly ? 1 : 0,
        'created_at_utc': now,
        'updated_at_utc': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAccount(String id) async {
    final db = await database;
    await db.delete('social_accounts', where: 'id = ?', whereArgs: [id]);
  }

  // --- Content Post Operations ---
  Future<List<ContentPost>> getAllPosts() async {
    final db = await database;
    final maps = await db.query('content_posts', orderBy: 'updated_at_utc DESC');
    return maps.map((m) {
      List<String> dests = [];
      if (m['destination_account_ids'] != null) {
        try {
          final dec = jsonDecode(m['destination_account_ids'] as String);
          if (dec is List) dests = dec.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      List<String> media = [];
      if (m['media_asset_ids'] != null) {
        try {
          final dec = jsonDecode(m['media_asset_ids'] as String);
          if (dec is List) media = dec.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      List<String> tags = [];
      if (m['tags'] != null) {
        try {
          final dec = jsonDecode(m['tags'] as String);
          if (dec is List) tags = dec.map((e) => e.toString()).toList();
        } catch (_) {}
      }

      PublishJobStatus status = PublishJobStatus.draft;
      try {
        status = PublishJobStatus.values.byName(m['status'] as String);
      } catch (_) {}

      return ContentPost(
        id: m['id'] as String,
        brandId: m['brand_id'] as String,
        title: m['title'] as String,
        defaultCaption: m['default_caption'] as String,
        destinationAccountIds: dests,
        mediaAssetIds: media,
        campaign: m['campaign'] as String?,
        tags: tags,
        status: status,
        scheduledAtUtc: m['scheduled_at_utc'] != null
            ? DateTime.tryParse(m['scheduled_at_utc'] as String)
            : null,
        createdAtUtc: DateTime.tryParse(m['created_at_utc'] as String? ?? '') ?? DateTime.now().toUtc(),
        updatedAtUtc: DateTime.tryParse(m['updated_at_utc'] as String? ?? '') ?? DateTime.now().toUtc(),
      );
    }).toList();
  }

  Future<void> savePost(ContentPost post) async {
    final db = await database;
    await db.insert(
      'content_posts',
      {
        'id': post.id,
        'brand_id': post.brandId,
        'title': post.title,
        'default_caption': post.defaultCaption,
        'destination_account_ids': jsonEncode(post.destinationAccountIds),
        'media_asset_ids': jsonEncode(post.mediaAssetIds),
        'campaign': post.campaign,
        'tags': jsonEncode(post.tags),
        'status': post.status.name,
        'scheduled_at_utc': post.scheduledAtUtc?.toIso8601String(),
        'created_at_utc': post.createdAtUtc.toIso8601String(),
        'updated_at_utc': post.updatedAtUtc.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePost(String id) async {
    final db = await database;
    await db.delete('content_posts', where: 'id = ?', whereArgs: [id]);
    await db.delete('publish_jobs', where: 'content_post_id = ?', whereArgs: [id]);
    await db.delete('post_variants', where: 'content_post_id = ?', whereArgs: [id]);
  }

  // --- Publish Job Operations ---
  Future<List<PublishJob>> getAllJobs() async {
    final db = await database;
    final maps = await db.query('publish_jobs', orderBy: 'updated_at_utc DESC');
    return maps.map((m) {
      PublishJobStatus status = PublishJobStatus.draft;
      try {
        status = PublishJobStatus.values.byName(m['status'] as String);
      } catch (_) {}

      ErrorCategory? errorCat;
      if (m['last_error_category'] != null) {
        try {
          errorCat = ErrorCategory.values.byName(m['last_error_category'] as String);
        } catch (_) {}
      }

      return PublishJob(
        id: m['id'] as String,
        contentPostId: m['content_post_id'] as String,
        postVariantId: (m['post_variant_id'] as String?) ?? 'variant_default',
        socialAccountId: m['social_account_id'] as String,
        idempotencyKey: m['idempotency_key'] as String,
        status: status,
        isManual: (m['is_manual'] as int? ?? 0) == 1,
        attemptCount: (m['attempt_count'] as int?) ?? 0,
        scheduledAtUtc: m['scheduled_at_utc'] != null
            ? DateTime.tryParse(m['scheduled_at_utc'] as String)
            : null,
        publishedAtUtc: m['published_at_utc'] != null
            ? DateTime.tryParse(m['published_at_utc'] as String)
            : null,
        externalPostId: m['external_post_id'] as String?,
        externalUrl: m['external_url'] as String?,
        lastErrorCode: m['last_error_code'] as String?,
        lastErrorCategory: errorCat,
        lastErrorMessage: m['last_error_message'] as String?,
        lastErrorAtUtc: m['last_error_at_utc'] != null
            ? DateTime.tryParse(m['last_error_at_utc'] as String)
            : null,
        createdAtUtc: DateTime.tryParse(m['created_at_utc'] as String? ?? '') ?? DateTime.now().toUtc(),
        updatedAtUtc: DateTime.tryParse(m['updated_at_utc'] as String? ?? '') ?? DateTime.now().toUtc(),
      );
    }).toList();
  }

  Future<void> saveJob(PublishJob job) async {
    final db = await database;
    await db.insert(
      'publish_jobs',
      {
        'id': job.id,
        'content_post_id': job.contentPostId,
        'post_variant_id': job.postVariantId,
        'social_account_id': job.socialAccountId,
        'idempotency_key': job.idempotencyKey,
        'status': job.status.name,
        'is_manual': job.isManual ? 1 : 0,
        'attempt_count': job.attemptCount,
        'scheduled_at_utc': job.scheduledAtUtc?.toIso8601String(),
        'published_at_utc': job.publishedAtUtc?.toIso8601String(),
        'external_post_id': job.externalPostId,
        'external_url': job.externalUrl,
        'last_error_code': job.lastErrorCode,
        'last_error_category': job.lastErrorCategory?.name,
        'last_error_message': job.lastErrorMessage,
        'last_error_at_utc': job.lastErrorAtUtc?.toIso8601String(),
        'created_at_utc': job.createdAtUtc.toIso8601String(),
        'updated_at_utc': job.updatedAtUtc.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteJob(String id) async {
    final db = await database;
    await db.delete('publish_jobs', where: 'id = ?', whereArgs: [id]);
  }

  // --- Audit Events ---
  Future<List<AuditEvent>> getAllAuditEvents() async {
    final db = await database;
    final maps = await db.query('audit_events', orderBy: 'created_at_utc DESC');
    return maps.map((m) {
      Map<String, dynamic> meta = {};
      if (m['metadata_json'] != null) {
        try {
          final dec = jsonDecode(m['metadata_json'] as String);
          if (dec is Map<String, dynamic>) meta = dec;
        } catch (_) {}
      }
      return AuditEvent(
        id: m['id'] as String,
        actor: m['actor'] as String,
        eventType: m['event_type'] as String,
        entityType: m['entity_type'] as String,
        entityId: m['entity_id'] as String,
        description: m['description'] as String,
        metadataSanitized: meta,
        createdAtUtc: DateTime.tryParse(m['created_at_utc'] as String? ?? '') ?? DateTime.now().toUtc(),
      );
    }).toList();
  }

  Future<void> saveAuditEvent(AuditEvent event) async {
    final db = await database;
    await db.insert(
      'audit_events',
      {
        'id': event.id,
        'actor': event.actor,
        'event_type': event.eventType,
        'entity_type': event.entityType,
        'entity_id': event.entityId,
        'description': event.description,
        'metadata_json': jsonEncode(event.metadataSanitized),
        'created_at_utc': event.createdAtUtc.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Save or update authenticated user profile into local SQLite (Safe profile metadata only)
  Future<void> saveUserProfile({
    required String id,
    required String name,
    required String email,
    String? photoUrl,
    required String provider,
    String? rawData,
  }) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(
      'user_profiles',
      {
        'id': id,
        'name': name,
        'email': email,
        'photo_url': photoUrl,
        'provider': provider,
        'raw_data': rawData,
        'created_at_utc': now,
        'updated_at_utc': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve the most recently authenticated user profile from local SQLite
  Future<Map<String, dynamic>?> getUserProfile() async {
    final db = await database;
    final list = await db.query(
      'user_profiles',
      orderBy: 'updated_at_utc DESC',
      limit: 1,
    );
    if (list.isEmpty) return null;
    return list.first;
  }

  /// Clear user profile from local SQLite on sign out
  Future<void> clearUserProfile() async {
    final db = await database;
    await db.delete('user_profiles');
  }

  /// Save key-value setting in local SQLite
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get key-value setting from local SQLite
  Future<String?> getSetting(String key) async {
    final db = await database;
    final list = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (list.isEmpty) return null;
    return list.first['value'] as String?;
  }

  /// Get all key-value settings from local SQLite
  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final list = await db.query('app_settings');
    final result = <String, String>{};
    for (final row in list) {
      final key = row['key'] as String?;
      final value = row['value'] as String?;
      if (key != null && value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  // ==============================================================================
  // Anti-Abuse & Lifetime Free Bonus Protection (Survives Account Deletions)
  // ==============================================================================

  /// Records an immutable anti-abuse tombstone entry when an account is deleted.
  /// This table survives normal account reset to prevent bonus farming cycles.
  Future<void> recordAntiAbuseTombstone({
    required String email,
    required String deviceId,
    List<String> channelIds = const [],
    Map<String, dynamic>? telemetry,
  }) async {
    final db = await database;
    final cleanEmail = email.trim().toLowerCase();
    final identityKey = cleanEmail.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final nowUtc = DateTime.now().toUtc().toIso8601String();

    await db.insert(
      'anti_abuse_tombstones',
      {
        'identity_hash': identityKey,
        'email': cleanEmail,
        'device_id': deviceId,
        'deleted_at_utc': nowUtc,
        'lifetime_coins_exhausted': 1,
        'metadata_json': jsonEncode({
          'channel_ids': channelIds,
          'telemetry': telemetry,
          'deleted_at': nowUtc,
        }),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Also tombstone by device hardware signature if available
    if (deviceId.isNotEmpty && deviceId != 'unknown_device') {
      final devKey = 'dev_${deviceId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';
      await db.insert(
        'anti_abuse_tombstones',
        {
          'identity_hash': devKey,
          'email': cleanEmail,
          'device_id': deviceId,
          'deleted_at_utc': nowUtc,
          'lifetime_coins_exhausted': 1,
          'metadata_json': jsonEncode({
            'channel_ids': channelIds,
            'is_device_record': true,
          }),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Checks if an email or physical device has an active anti-abuse tombstone recorded
  Future<bool> isIdentityTombstoned({required String email, String? deviceId}) async {
    final db = await database;
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isNotEmpty) {
      final identityKey = cleanEmail.replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final byEmail = await db.query(
        'anti_abuse_tombstones',
        where: 'identity_hash = ? OR email = ?',
        whereArgs: [identityKey, cleanEmail],
        limit: 1,
      );
      if (byEmail.isNotEmpty) return true;
    }

    if (deviceId != null && deviceId.isNotEmpty && deviceId != 'unknown_device') {
      final devKey = 'dev_${deviceId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';
      final byDev = await db.query(
        'anti_abuse_tombstones',
        where: 'identity_hash = ? OR device_id = ?',
        whereArgs: [devKey, deviceId],
        limit: 1,
      );
      if (byDev.isNotEmpty) return true;
    }

    return false;
  }

  // ==============================================================================
  // User Wallet & Coin Transactions (Real Database Ledger)
  // ==============================================================================

  /// Returns user's verified coin balance from SQLite database
  Future<int> getCoinBalance(String userId) async {
    final db = await database;
    final list = await db.query(
      'user_wallets',
      columns: ['balance'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (list.isEmpty) {
      await initUserWallet(userId);
      return 0;
    }
    return list.first['balance'] as int? ?? 0;
  }

  /// Initializes a real database wallet record and optional grant transaction for the user
  Future<void> initUserWallet(String userId, {int initialCoins = 0, String? grantType, String? grantDesc}) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      final existing = await txn.query(
        'user_wallets',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (existing.isNotEmpty) return;

      await txn.insert('user_wallets', {
        'user_id': userId,
        'balance': initialCoins,
        'total_earned': initialCoins,
        'total_spent': 0,
        'created_at_utc': now,
        'updated_at_utc': now,
      });

      if (initialCoins > 0) {
        final txId = 'tx-${DateTime.now().millisecondsSinceEpoch}-${userId.hashCode.abs().toString().padLeft(4, '0')}';
        await txn.insert('coin_transactions', {
          'id': txId,
          'user_id': userId,
          'amount': initialCoins,
          'balance_after': initialCoins,
          'type': grantType ?? 'welcome_grant',
          'description': grantDesc ?? 'Welcome Bonus Coins',
          'reference_id': null,
          'created_at_utc': now,
          'updated_at_utc': now,
        });
      }
    });
  }

  /// Adds coins to the user's database wallet and records a transaction
  Future<int> addCoinsToWallet({
    required String userId,
    required int amount,
    required String type,
    required String description,
    String? referenceId,
  }) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();

    return await db.transaction<int>((txn) async {
      final list = await txn.query(
        'user_wallets',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      int currentBalance = 0;
      int currentEarned = 0;
      int currentSpent = 0;

      if (list.isEmpty) {
        currentBalance = 0;
      } else {
        currentBalance = list.first['balance'] as int? ?? 0;
        currentEarned = list.first['total_earned'] as int? ?? 0;
        currentSpent = list.first['total_spent'] as int? ?? 0;
      }

      final newBalance = currentBalance + amount;
      final newEarned = currentEarned + amount;

      await txn.insert(
        'user_wallets',
        {
          'user_id': userId,
          'balance': newBalance,
          'total_earned': newEarned,
          'total_spent': currentSpent,
          'created_at_utc': list.isEmpty ? now : (list.first['created_at_utc'] ?? now),
          'updated_at_utc': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final txId = 'tx-${DateTime.now().millisecondsSinceEpoch}-${userId.hashCode.abs().toString().padLeft(4, '0')}';
      await txn.insert('coin_transactions', {
        'id': txId,
        'user_id': userId,
        'amount': amount,
        'balance_after': newBalance,
        'type': type,
        'description': description,
        'reference_id': referenceId,
        'created_at_utc': now,
        'updated_at_utc': now,
      });

      return newBalance;
    });
  }

  /// Deducts 1 coin from user's database wallet when publishing/scheduling beyond daily quota
  Future<bool> spendCoinFromWallet({
    required String userId,
    required String description,
    String? postId,
  }) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();

    return await db.transaction<bool>((txn) async {
      final list = await txn.query(
        'user_wallets',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (list.isEmpty) return false;
      final currentBalance = list.first['balance'] as int? ?? 0;
      if (currentBalance <= 0) return false;

      final currentSpent = list.first['total_spent'] as int? ?? 0;
      final newBalance = currentBalance - 1;
      final newSpent = currentSpent + 1;

      await txn.update(
        'user_wallets',
        {
          'balance': newBalance,
          'total_spent': newSpent,
          'updated_at_utc': now,
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      final txId = 'tx-${DateTime.now().millisecondsSinceEpoch}-${userId.hashCode.abs().toString().padLeft(4, '0')}';
      await txn.insert('coin_transactions', {
        'id': txId,
        'user_id': userId,
        'amount': -1,
        'balance_after': newBalance,
        'type': 'post_publish',
        'description': description,
        'reference_id': postId,
        'created_at_utc': now,
        'updated_at_utc': now,
      });

      return true;
    });
  }

  /// Returns verified coin transactions from SQLite database
  Future<List<Map<String, dynamic>>> getCoinTransactions(String userId, {int limit = 100}) async {
    final db = await database;
    return await db.query(
      'coin_transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at_utc DESC',
      limit: limit,
    );
  }

  // ==============================================================================
  // 2-Day Publishing Pass Operations (10 Coins = 2 Posts over 2 Days)
  // ==============================================================================

  /// Returns the current active and unexpired publishing pass for the user
  Future<PublishingPass?> getActivePublishingPass(String userId) async {
    final db = await database;
    final nowUtc = DateTime.now().toUtc();
    final rows = await db.query(
      'publishing_passes',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'activated_at_utc DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final pass = PublishingPass.fromJson(rows.first);

    // If 48 hours have elapsed or posts exhausted, mark inactive in SQLite
    if (nowUtc.isAfter(pass.expiresAt) || pass.postsUsed >= pass.maxPosts) {
      await db.update(
        'publishing_passes',
        {
          'is_active': 0,
          'updated_at_utc': nowUtc.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [pass.id],
      );
      return null;
    }

    return pass;
  }

  /// Activates a 2-day publishing pass by deducting 10 coins atomically
  Future<PublishingPass?> activatePublishingPass({
    required String userId,
    int costCoins = 10,
    int maxPosts = 2,
    int durationDays = 2,
  }) async {
    final db = await database;
    final nowUtc = DateTime.now().toUtc();
    final nowStr = nowUtc.toIso8601String();
    final expiresStr = nowUtc.add(Duration(days: durationDays)).toIso8601String();

    return await db.transaction<PublishingPass?>((txn) async {
      // 1. Verify coin balance >= costCoins
      final walletRows = await txn.query(
        'user_wallets',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      final balance = walletRows.isNotEmpty ? (walletRows.first['balance'] as int? ?? 0) : 0;
      if (balance < costCoins) {
        return null; // Insufficient coins
      }

      final spent = walletRows.isNotEmpty ? (walletRows.first['total_spent'] as int? ?? 0) : 0;
      final newBalance = balance - costCoins;
      final newSpent = spent + costCoins;

      // 2. Deduct coins from wallet
      await txn.update(
        'user_wallets',
        {
          'balance': newBalance,
          'total_spent': newSpent,
          'updated_at_utc': nowStr,
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // 3. Record transaction in ledger
      final txId = 'tx-${nowUtc.millisecondsSinceEpoch}-${userId.hashCode.abs().toString().padLeft(4, '0')}';
      await txn.insert('coin_transactions', {
        'id': txId,
        'user_id': userId,
        'amount': -costCoins,
        'balance_after': newBalance,
        'type': 'pass_activation',
        'description': '$durationDays-Day Pass (2 Posts for $costCoins Coins)',
        'reference_id': null,
        'created_at_utc': nowStr,
        'updated_at_utc': nowStr,
      });

      // 4. Mark all existing passes for this user inactive
      await txn.update(
        'publishing_passes',
        {'is_active': 0, 'updated_at_utc': nowStr},
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // 5. Create new active pass
      final passId = 'pass-${nowUtc.millisecondsSinceEpoch}-${userId.hashCode.abs().toString().padLeft(4, '0')}';
      final passData = {
        'id': passId,
        'user_id': userId,
        'cost_coins': costCoins,
        'max_posts': maxPosts,
        'posts_used': 0,
        'duration_days': durationDays,
        'activated_at_utc': nowStr,
        'expires_at_utc': expiresStr,
        'is_active': 1,
        'created_at_utc': nowStr,
        'updated_at_utc': nowStr,
      };

      await txn.insert('publishing_passes', passData);

      return PublishingPass.fromJson(passData);
    });
  }

  /// Consumes 1 post from the user's active pass
  Future<PublishingPass?> consumePostFromPass({
    required String userId,
    String? postId,
  }) async {
    final db = await database;
    final nowUtc = DateTime.now().toUtc();
    final nowStr = nowUtc.toIso8601String();

    return await db.transaction<PublishingPass?>((txn) async {
      final rows = await txn.query(
        'publishing_passes',
        where: 'user_id = ? AND is_active = 1',
        whereArgs: [userId],
        orderBy: 'activated_at_utc DESC',
        limit: 1,
      );

      if (rows.isEmpty) return null;
      final currentPass = PublishingPass.fromJson(rows.first);

      if (nowUtc.isAfter(currentPass.expiresAt)) {
        await txn.update(
          'publishing_passes',
          {'is_active': 0, 'updated_at_utc': nowStr},
          where: 'id = ?',
          whereArgs: [currentPass.id],
        );
        return null;
      }

      final newUsed = currentPass.postsUsed + 1;
      final shouldDeactivate = newUsed >= currentPass.maxPosts;

      await txn.update(
        'publishing_passes',
        {
          'posts_used': newUsed,
          'is_active': shouldDeactivate ? 0 : 1,
          'updated_at_utc': nowStr,
        },
        where: 'id = ?',
        whereArgs: [currentPass.id],
      );

      // Record post usage in coin transactions ledger (audited record)
      final txId = 'tx-${nowUtc.millisecondsSinceEpoch}-${userId.hashCode.abs().toString().padLeft(4, '0')}';
      final balance = await getCoinBalance(userId);
      await txn.insert('coin_transactions', {
        'id': txId,
        'user_id': userId,
        'amount': 0,
        'balance_after': balance,
        'type': 'post_published',
        'description': 'Post published ($newUsed of ${currentPass.maxPosts} used on 2-Day Pass)',
        'reference_id': postId,
        'created_at_utc': nowStr,
        'updated_at_utc': nowStr,
      });

      return currentPass.copyWith(
        postsUsed: newUsed,
        isActive: !shouldDeactivate,
      );
    });
  }

  /// Saves or reconciles a publishing pass from Firebase Cloud Firestore
  Future<void> savePublishingPass(Map<String, dynamic> passData) async {
    final db = await database;
    final pass = PublishingPass.fromJson(passData);
    if (pass.id.isEmpty) return;

    final dbMap = pass.toDbMap();
    if (passData.containsKey('created_at_utc') && passData['created_at_utc'] != null) {
      dbMap['created_at_utc'] = passData['created_at_utc'].toString();
    }
    if (passData.containsKey('updated_at_utc') && passData['updated_at_utc'] != null) {
      dbMap['updated_at_utc'] = passData['updated_at_utc'].toString();
    }
    if (passData.containsKey('synced_at_utc') && passData['synced_at_utc'] != null) {
      dbMap['synced_at_utc'] = passData['synced_at_utc'].toString();
    }

    final existing = await db.query('publishing_passes', where: 'id = ?', whereArgs: [pass.id], limit: 1);
    if (existing.isEmpty) {
      await db.insert('publishing_passes', dbMap, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update('publishing_passes', dbMap, where: 'id = ?', whereArgs: [pass.id]);
    }
  }

  /// Returns historical publishing passes for this user
  Future<List<PublishingPass>> getPublishingPassHistory(String userId, {int limit = 10}) async {
    final db = await database;
    final rows = await db.query(
      'publishing_passes',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'activated_at_utc DESC',
      limit: limit,
    );
    return rows.map((r) => PublishingPass.fromJson(r)).toList();
  }

  // ==============================================================================
  // Local-First Outbox Synchronization Engine Helpers
  // ==============================================================================

  /// Returns all records for a table (for complete cloud backup)
  Future<List<Map<String, dynamic>>> getAllRecords(String tableName) async {
    final db = await database;
    await _ensureSyncColumns(db, tableName);
    return await db.query(tableName);
  }

  /// Returns un-synced dirty records for a specific table
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String tableName) async {
    final db = await database;
    await _ensureSyncColumns(db, tableName);
    return await db.rawQuery('''
      SELECT * FROM $tableName 
      WHERE synced_at_utc IS NULL 
         OR updated_at_utc > synced_at_utc
    ''');
  }

  /// Marks a batch of record IDs as synced at UTC
  Future<void> markRecordsAsSynced({
    required String tableName,
    required List<String> recordIds,
    required String syncedAtUtc,
  }) async {
    if (recordIds.isEmpty) return;
    final db = await database;
    await _ensureSyncColumns(db, tableName);
    final batch = db.batch();
    for (final id in recordIds) {
      batch.update(
        tableName,
        {'synced_at_utc': syncedAtUtc},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Upserts records pulled from central sync server applying Last-Write-Wins (LWW)
  Future<void> upsertRemoteDelta({
    required String tableName,
    required List<Map<String, dynamic>> records,
    required String syncedAtUtc,
  }) async {
    if (records.isEmpty) return;
    final db = await database;

    for (final record in records) {
      final id = record['id'] as String?;
      if (id == null) continue;

      final existing = await db.query(tableName, where: 'id = ?', whereArgs: [id], limit: 1);
      final mutable = Map<String, dynamic>.from(record);
      mutable['synced_at_utc'] = syncedAtUtc;

      if (existing.isEmpty) {
        await db.insert(tableName, mutable, conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        final localUpdated = existing.first['updated_at_utc'] as String?;
        final remoteUpdated = record['updated_at_utc'] as String?;

        // LWW: Only apply if remote is newer or equal
        if (localUpdated == null || remoteUpdated == null || remoteUpdated.compareTo(localUpdated) >= 0) {
          await db.update(tableName, mutable, where: 'id = ?', whereArgs: [id]);
        }
      }
    }
  }

  // --- Org Member Operations ---

  Future<List<OrgMember>> getOrgMembers(String orgId) async {
    final db = await database;
    final rows = await db.query(
      'org_members',
      where: 'org_id = ? AND is_active = 1',
      whereArgs: [orgId],
      orderBy: 'joined_at_utc ASC',
    );
    return rows.map((r) => OrgMember.fromJson(r)).toList();
  }

  Future<OrgMember?> getOrgMemberByUser(String orgId, String userId) async {
    final db = await database;
    final rows = await db.query(
      'org_members',
      where: 'org_id = ? AND user_id = ? AND is_active = 1',
      whereArgs: [orgId, userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return OrgMember.fromJson(rows.first);
  }

  Future<void> upsertOrgMember(OrgMember member) async {
    final db = await database;
    final data = member.toJson();
    data['updated_at_utc'] = DateTime.now().toUtc().toIso8601String();
    await db.insert('org_members', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteOrgMember(String memberId) async {
    final db = await database;
    await db.delete('org_members', where: 'id = ?', whereArgs: [memberId]);
  }

  // --- Org Invite Operations ---

  Future<List<OrgInvite>> getOrgInvites(String orgId) async {
    final db = await database;
    final rows = await db.query(
      'org_invites',
      where: 'org_id = ?',
      whereArgs: [orgId],
      orderBy: 'created_at_utc DESC',
    );
    return rows.map((r) => OrgInvite.fromJson(r)).toList();
  }

  Future<OrgInvite?> getOrgInviteByToken(String token) async {
    final db = await database;
    final rows = await db.query(
      'org_invites',
      where: 'token = ?',
      whereArgs: [token],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return OrgInvite.fromJson(rows.first);
  }

  Future<void> insertOrgInvite(OrgInvite invite) async {
    final db = await database;
    final data = invite.toJson();
    data['updated_at_utc'] = DateTime.now().toUtc().toIso8601String();
    await db.insert('org_invites', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateOrgInviteStatus(String inviteId, InviteStatus status) async {
    final db = await database;
    await db.update(
      'org_invites',
      {
        'status': status.name,
        'updated_at_utc': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [inviteId],
    );
  }

  Future<void> deleteOrgInvite(String inviteId) async {
    final db = await database;
    await db.delete('org_invites', where: 'id = ?', whereArgs: [inviteId]);
  }
}

