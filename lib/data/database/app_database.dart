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

  Future<void> saveBrand(Brand brand) async {
    final db = await database;
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
    await db.insert(
      'channel_groups',
      group.toMap(),
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
        'created_at_utc': DateTime.now().toUtc().toIso8601String(),
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
}
