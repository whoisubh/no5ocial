# MEMORY.md — no5ocial Living Technical Memory & Session History

> **Purpose**: This file is the single source of truth for **no5ocial**'s architecture, complete feature catalog, implementation details, and historical session logs.
> 
> **MANDATORY FOR ALL AI AGENTS**:
> 1. **At Session Start**: Read this entire file to understand existing features, design constraints, and the latest completed block.
> 2. **After Any Feature/Update**: Append a new standardized session block at the bottom of Section 4 with date, AI model metadata, files touched, technical decisions, and next steps.

---

## 1. System Overview & Core Architecture

`no5ocial` is a private, multi-brand social media publishing console and operations engine built for **Shaadow** and its creator brands (*Shaadow, Shaadow Works, Boofer, Favtunes, Galaxious, Owl & Fowl Studios*). It replaces expensive third-party schedulers while guaranteeing zero secret leakage, strict Google authentication, and preflight compliance across destination platforms.

### Tech Stack & Core Libraries
- **Language & Framework**: Dart 3 (SDK `^3.13.0`), Flutter 3 (Material 3 with responsive layout for Desktop, Tablet, and Mobile).
- **State Management**: `AppState` (`ChangeNotifier`) with dependency injection via constructor; `ListenableBuilder` reactive rendering.
- **Local Database**: Cross-platform SQLite via `sqflite`, `sqflite_common_ffi` (Desktop), and `sqflite_common_ffi_web` (WASM / Web).
- **Cloud Backend**:
  - **Firebase Auth**: Mandatory real Google Sign-In (`google_sign_in: ^6.2.2`). No dummy credentials or guest bypasses.
  - **Cloud Firestore**: Two-way synchronization of brands, accounts, drafts, and invitation tokens (`cloud_firestore: ^7.0.0`).
  - **Firebase Cloud Messaging**: Push alerts for scheduled jobs, failures, and operational updates (`firebase_messaging: ^17.0.1`).
- **Security & Biometrics**: `local_auth: ^3.0.2` (biometric app lock), `passkeys: ^2.23.1` (WebAuthn credentials).
- **Monetization & Ads**: AppLovin MAX / Google Mobile Ads mediation (`google_mobile_ads: ^9.1.0`), rewarded video ads, Day Pass system, anti-abuse telemetry.
- **Networking & Connectivity**: `http: ^1.6.0`, `connectivity_plus: ^7.3.2` for live connection status.
- **Branding Assets**:
  - Light mode: `assets/logo/no5ocial.png`
  - Dark mode / dark app bars: `assets/logo/no5ocial_white.png`
  - App icons, favicons, badges: `assets/logo/no5ocial_cropped.png`

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   Flutter Presentation Layer                           │
│  MainScaffold (Tabs 0-4) │ Composer │ MediaPreview │ Settings & Sheets │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │
┌────────────────────────────────────▼───────────────────────────────────┐
│                    Application State Layer                             │
│       AppState (ChangeNotifier)  │  BiometricLock  │  Monetization     │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │
┌────────────────────────────────────▼───────────────────────────────────┐
│                         Domain Layer                                   │
│  Typed Models │ PreflightValidator │ CompositePublishingAdapter        │
└──────────────────┬─────────────────────────────────┬───────────────────┘
                   │                                 │
┌──────────────────▼──────────────────┐   ┌──────────▼───────────────────┐
│            Data Layer               │   │      External Services       │
│  AppDatabase (SQLite)               │   │  Firebase (Auth, Firestore,  │
│  7 Repositories (Post, Brand, etc.) │   │  FCM) │ Social REST APIs     │
└─────────────────────────────────────┘   └──────────────────────────────┘
```

---

## 2. Comprehensive Feature Catalog & Implementation Details

### 2.1. Authentication, Sessions & Security
- **Mandatory Google Sign-In** (`lib/core/services/google_auth_service.dart`, `lib/presentation/screens/auth/login_screen.dart`):
  - Strictly requires authorized Google credentials.
  - Zero mock logins, "Skip Login", or offline lead bypass buttons allowed anywhere in code.
  - Active route guards on `MainScaffold`, `HomeScreen`, and all dashboard subroutes redirect unauthenticated users to `/login`.
- **Session Management & Expiry** (`lib/core/services/session_service.dart`, `lib/presentation/widgets/session_expired_sheet.dart`):
  - Tracks session activity and idle duration.
  - Surfaces `SessionExpiredSheet` with masked email when session expires.
- **Biometric App Lock & Passkeys** (`lib/core/services/biometric_lock_service.dart`, `passkey_service.dart`, `biometric_lock_overlay.dart`):
  - Hardware fingerprint / Face ID biometric prompt on native app resume.
  - WebAuthn passkey registration and authentication.
- **Global Error Handling & Redaction** (`lib/core/errors/app_error_handler.dart`, `app_error.dart`, `lib/core/utils/string_sanitizer.dart`):
  - 5-digit structured Error IDs (e.g., `12003` for auth failure) across all toasts.
  - Automatic scrubbing of OAuth Bearer tokens, query secrets, and authorization headers from logs and error dialogs.

### 2.2. Multi-Brand & Team Organization
- **Brand Portfolio** (`lib/domain/models/brand.dart`, `lib/data/repositories/brand_repository.dart`):
  - Multi-brand architecture: Shaadow, Shaadow Works, Boofer, Favtunes, Galaxious, Owl & Fowl Studios.
  - Default brand generation on first run; brand switcher available throughout the UI.
- **Channel Groups** (`lib/domain/models/channel_group.dart`, `lib/data/repositories/group_repository.dart`):
  - Group social accounts into operational bundles (e.g., "Main Studio Channels", "Gaming Brands") for 1-tap multi-destination selection.
- **Role-Based Access Control** (`lib/domain/enums/org_role.dart`, `lib/domain/models/org_member.dart`):
  - Roles: `owner`, `admin`, `editor`, `publisher`, `viewer`.
  - Member management sheet (`team_management_sheet.dart`) and Firestore-backed invites.
- **Fullscreen Invite Acceptance Flow** (`lib/presentation/screens/invite/invite_accept_screen.dart`):
  - Handles `/invite?token=...` deep links.
  - Cloud Firestore token lookup, expiration check, and automatic role assignment upon sign-in.
- **Company Settings & Branding Rules** (`lib/presentation/screens/settings/company_settings_screen.dart`, `content_branding_settings_view.dart`):
  - Immutable registered company name (anti-abuse protection).
  - Configurable brand guidelines: default tone, signature hashtags, and watermark settings.

### 2.3. Composer & Multi-Platform Preflight Engine
- **Multi-Destination Publishing Composer** (`lib/presentation/screens/composer/composer_screen.dart`):
  - Target multiple accounts across different platforms simultaneously.
  - Platform-specific caption tabs allowing customized messaging per destination while retaining a default fallback caption.
  - Real-time character counters and hashtag limit indicators.
  - Scheduling system persisting in strict UTC while displaying in configured local timezone.
  - Tag & badge input fields (`tag_badge_input_field.dart`).
- **Preflight Validation Engine** (`lib/domain/validators/preflight_validator.dart`):
  - Enforces platform constraints before enqueueing:
    - **X (Twitter)**: ≤ 280 characters.
    - **Instagram**: ≤ 2,200 characters, ≤ 30 hashtags, media required.
    - **YouTube**: ≤ 5,000 characters description, ≤ 100 characters title (strictly required).
    - **LinkedIn**: ≤ 3,000 characters.
    - **Threads**: ≤ 500 characters.
  - **Cross-Brand Mismatch Warning**: Triggers blocker/warning when publishing to an account belonging to a different brand than the draft.
  - Connection status verification: Blocks publishing if destination account is disconnected or revoked.
- **15-Second Manual Publishing Handoff** (`lib/presentation/screens/composer/manual_handoff_sheet.dart`):
  - When direct API access is restricted, cost-prohibitive, or unauthorized, provides 1-tap caption clipboard copy, media staging download, and verification checklist.

### 2.4. Media Staging & Fullscreen Preview
- **Media Preview Screen** (`lib/presentation/screens/media/media_preview_screen.dart`):
  - Interactive zoomable image viewer and video player (`video_player: ^2.14.1`).
  - Real-time aspect ratio calculation (1:1 square, 9:16 vertical Reel/Short, 16:9 landscape).
  - Media dimension and format validation against platform specs.
- **Video Thumbnail Extractor** (`lib/core/services/video_thumbnail_service.dart`):
  - Generates preview frames for uploaded videos.
- **Media Hosting Service** (`lib/core/services/media_hosting_service.dart`):
  - Local staging and short-lived signed URL generation for uploads.

### 2.5. Publishing Pipeline & Adapters
- **Domain Adapter Architecture** (`lib/domain/adapters/`):
  - `CompositePublishingAdapter`: Routes jobs to platform-specific REST adapters.
  - Platform adapters:
    - `InstagramPublishingAdapter` (Instagram Graph API container & publish flow).
    - `LinkedInPublishingAdapter` (LinkedIn UGC / Community Management API).
    - `XPublishingAdapter` (X API v2 tweets endpoint with media upload).
    - `YouTubePublishingAdapter` (YouTube Data API v3 video insert).
    - `ThreadsPublishingAdapter` (Meta Threads API).
    - `FakePublishingAdapter` (strictly labeled test fake for unit/widget tests; never committed as real production success).
- **Independent Job Tracking** (`lib/domain/models/publish_job.dart`, `publish_attempt.dart`):
  - Multi-destination publications generate isolated `PublishJob` records per account.
  - Partial failure on one platform does not cancel or roll back successful posts on other platforms.
- **Ambiguous Timeout Safety**:
  - Timeouts after publish requests lock retries behind explicit duplicate-risk confirmation.

### 2.6. Content Library & Calendar
- **Content Library** (`lib/presentation/screens/content/content_library_screen.dart`):
  - Searchable, filterable repository of drafts, scheduled posts, and published archives.
  - Filter by brand, publication status, date range, and text query.
- **Calendar Operations** (`lib/presentation/screens/calendar/calendar_screen.dart`):
  - Interactive calendar powered by `table_calendar: ^3.3.0`.
  - Visual timeline of scheduled social posts across all brands.
  - Calendar export helper (`lib/core/utils/calendar_export_helper.dart`) to `.ics` format.

### 2.7. Accounts & Channel Management
- **Accounts Registry** (`lib/presentation/screens/accounts/accounts_screen.dart`):
  - Manage linked social channels per brand.
  - Health checks: Token expiration warnings, re-authentication triggers, connection status chips.
  - OAuth deep link listener (`lib/core/services/oauth_callback_service.dart`).

### 2.8. Monetization, Coins & Anti-Abuse
- **Monetization Engine** (`lib/core/services/monetization_service.dart`):
  - **Account Plan Tiers**: `soloFree`, `creatorPass`, `agencyEnterprise`. Multi-person organizations automatically hide ads.
  - **Day Pass**: Unlocks unlimited publishing for 24 hours.
  - **Coin Economy**: Users earn coins via rewarded video ads or milestone achievements; coins are spent to publish jobs.
  - **Ceilings & Capping**: Hard ceiling of max 30 milestone coins to prevent automated abuse.
- **Rewarded Ad Mediation** (`lib/core/services/applovin_max_mediation_service.dart`):
  - AppLovin MAX & Google AdMob rewarded video integrations.
- **Anti-Abuse Telemetry** (`lib/core/services/device_telemetry_service.dart`):
  - Device fingerprinting, rooted device detection, single-email channel ownership enforcement.
- **Coin History Screen** (`lib/presentation/screens/settings/coin_history_screen.dart`):
  - Audit log of coin accruals, rewarded ad views, and publishing expenditures.

### 2.9. Offline-First Sync & Push Notifications
- **Network Connectivity Service** (`lib/core/services/connectivity_service.dart`):
  - Listens to connectivity changes (`connectivity_plus`). Prevents network requests while offline and initiates sync when connection is restored.
- **Local-First SQLite Database** (`lib/data/database/app_database.dart`):
  - 14 relational tables: `brands`, `channel_groups`, `social_accounts`, `content_posts`, `post_variants`, `media_assets`, `publish_jobs`, `audit_events`, `user_profiles`, `org_members`, `org_invites`, `user_wallets`, `coin_transactions`, `publishing_passes`.
  - Separated `clearTemporaryCache` (clears media files and draft caches) from destructive full reset.
- **FCM Push Notification Service** (`lib/core/services/fcm_notification_service.dart`):
  - Handles foreground, background, and notification tap actions with Android notification channels.

### 2.10. Internationalization & Static Web Shells
- **Localization** (`lib/l10n/`):
  - 8 language ARB files: English (`app_en.arb`), Spanish (`app_es.arb`), Hindi (`app_hi.arb`), Japanese (`app_ja.arb`), French (`app_fr.arb`), German (`app_de.arb`), Ukrainian (`app_uk.arb`), Chinese (`app_zh.arb`).
  - Auto-geolocation (`CountryService`, `CurrencyService`) to derive regional currency and language.
- **Public Legal Pages** (`lib/presentation/screens/legal/`):
  - `TermsScreen`, `PrivacyScreen`, `DisclaimerScreen` accessible publicly without login.
  - Wrapped with `LegalPageLayout` and official `assets/logo/no5ocial_white.png`.
- **Public Web Landing Page** (`lib/presentation/screens/landing/landing_screen.dart`):
  - Responsive desktop/mobile landing page featuring value proposition, brand switcher preview, pricing tiers, and Google login CTA.

---

## 3. Standardized Session Log Format

Every AI agent completing a task or milestone MUST append a block using this exact structure to Section 4:

```markdown
### Block [Index] — [YYYY-MM-DD] | [Short Title]
- **Timestamp**: [ISO 8601 or Local Date & Time]
- **AI Model**: [Exact model name used, e.g., Gemini 3.8 Flash (High)]
- **Agent/Role**: [e.g., Lead AI Architect / Antigravity Agent]
- **Objective / User Request**: [Direct quote or clear summary of the request]
- **Features Implemented & Architectural Changes**:
  - Detailed bulleted list of what was created, updated, or refactored.
- **Files Modified / Created**:
  - `path/to/file1.dart` — Description of changes.
  - `path/to/file2.dart` — Description of changes.
- **Verification & Testing Status**:
  - Tests run, analyzer status (`flutter analyze`, `flutter test`), or manual validation.
- **Current System State & Immediate Next Steps**:
  - State of working directory and exact, prioritized tasks to pick up next.
```

---

## 4. Chronological Session History Log

### Block 1 — 2026-10-29 | Comprehensive Baseline Architecture & Living Memory Setup
- **Timestamp**: 2026-10-29T10:30:00+05:30
- **AI Model**: Gemini 3.8 Flash (High)
- **Agent/Role**: Lead AI Architect (Antigravity)
- **Objective / User Request**:
  - "create MEMORY.md file add into AGENTS.md which keep brief each session conversations, and mostly helpful to continue what was lastly done"
  - "for now just write about everything no5ocial have features, implementation etc. but after this after each new feature/ updating anything and all memory will be keep writing here . date wise and other meta info about the ai model etc block wise"
- **Features Implemented & Architectural Changes**:
  - **Comprehensive Codebase Audit**: Inspected the entire `no5ocial` repository across `lib/` (presentation, state, domain, data, core services), `backend/`, `android/`, and configuration files.
  - **Living Technical Memory Established** (`MEMORY.md`):
    - Detailed the entire feature catalog (Google Auth, Session Security, Multi-Brand RBAC, Composer & Preflight, Media Preview, Platform Adapters, Content Library & Calendar, Monetization/Coins, Drift/SQLite Database, FCM Push Notifications, Localization).
    - Documented all 14 SQLite database tables and clean cache clearing separation.
    - Defined the standardized block-wise schema with mandatory metadata (date, AI model, files touched, verification, next steps).
  - **Updated Agent Rules** (`AGENTS.md`):
    - Added `MEMORY.md` to Rule 1 (mandatory pre-reading).
    - Added Rule 16 mandating reading `MEMORY.md` at session start and appending structured blocks with AI model metadata at session conclusion.
    - Added `MEMORY.md` update requirement to the Definition of Done and Collaboration Style.
- **Files Modified / Created**:
  - `MEMORY.md` (Created) — Comprehensive technical documentation, feature catalog, block template, and baseline session block.
  - `AGENTS.md` (Modified) — Integrated `MEMORY.md` protocol and block-wise logging requirement.
- **Verification & Testing Status**:
  - Codebase files inspected directly via file system and git.
  - Git status verified (`AGENTS.md` modified, `MEMORY.md` untracked, no unwanted changes).
- **Current System State & Immediate Next Steps**:
  - **Current State**: Working tree contains clean `AGENTS.md` and `MEMORY.md`. All Flutter screens, domain models, database layers, and services are fully documented.
  - **Immediate Next Steps**:
    1. **Social Platform Adapters (Server Boundary)**: Verify server-side OAuth flow and REST publishing adapters for YouTube, Instagram, X, LinkedIn, and Threads.
    2. **Scheduled Publishing Background Worker**: Connect scheduled posts in SQLite to Firestore backend job worker with idempotency checks.
    3. **Automated Test Coverage**: Run `flutter analyze` and `flutter test` across all new screens (`media_preview_screen.dart`, `company_settings_screen.dart`).

---

### Block 2 — 2026-10-29 | Lightweight Android SDK Setup & Toolchain Verification
- **Timestamp**: 2026-10-29T11:00:00+05:30
- **AI Model**: Gemini 3.8 Flash (High)
- **Agent/Role**: Systems & DevOps Specialist (Antigravity)
- **Objective / User Request**:
  - "how to add android sdk to run on android"
  - "is it necessary to download android studio ?"
- **Features Implemented & Architectural Changes**:
  - **Lightweight Android SDK Toolchain**: Installed and configured Android SDK completely without requiring the heavy Android Studio IDE (~150 MB CLI tools instead of ~1.2 GB IDE).
  - **Installed Required Packages**:
    - `cmdline-tools;latest` in `C:\Android\cmdline-tools\latest`
    - `platform-tools` (containing `adb.exe`)
    - `build-tools;34.0.0` and `build-tools;36.0.0`
    - `platforms;android-34` and `platforms;android-36` (matching Flutter 3.47.8 requirements)
  - **Configured Java & SDK Paths**:
    - Verified Microsoft OpenJDK 17 (`C:\Program Files\Microsoft\jdk-17.0.21.21-hotspot`).
    - Configured Flutter: `flutter config --android-sdk "C:\Android"` and `flutter config --jdk-dir "C:\Program Files\Microsoft\jdk-17.0.21.21-hotspot"`.
    - Added `C:\Android\platform-tools` to User `Path` so `adb` is accessible globally.
    - Accepted all Android SDK package licenses (`flutter doctor --android-licenses`).
  - **Device Detection**: Initialized ADB daemon and detected connected physical Android device (`ZD22298WVW`).
- **Files Modified / Created**:
  - `MEMORY.md` — Updated with Block 2.
- **Verification & Testing Status**:
  - Ran `flutter doctor -v`: Android toolchain passed with 100% green checkmark (`Android SDK version 36.0.0`, all licenses accepted, JDK 17 bound).
  - Verified ADB connection to device `ZD22298WVW`.
- **Current System State & Immediate Next Steps**:
  - **Current State**: Android SDK 36 is fully configured and ready. Physical phone `ZD22298WVW` is detected by ADB.
  - **Immediate Next Steps**:
    1. Authorize USB debugging prompt on phone (`ZD22298WVW`) by tapping "Always allow".
    2. Restart VS Code terminal to load updated environment paths.
    3. Run `flutter run -d android` to launch `no5ocial` directly on the physical phone.

---

### Block 3 — 2026-10-29 | Android Keystore SHA-1 Diagnostics & Google OAuth Verification
- **Timestamp**: 2026-10-29T12:08:00+05:30
- **AI Model**: Gemini 3.8 Flash (High)
- **Agent/Role**: Security & Identity Architect (Antigravity)
- **Objective / User Request**:
  - "google oauth setup required error" with attached device screenshot showing `ApiException 10 (DEVELOPER_ERROR)`.
- **Features Implemented & Architectural Changes**:
  - **Extracted Local Keystore Fingerprints**: Extracted exact SHA-1 and SHA-256 fingerprints from the newly generated local debug keystore at `C:\Users\RITS\.android\debug.keystore`:
    - SHA-1: `CC:02:53:FD:0A:82:94:87:7C:AE:8B:9D:77:8A:A3:CE:0E:E1:4F:E9`
    - SHA-256: `FD:35:4D:70:07:02:FD:B6:63:45:B9:9B:25:40:16:92:E1:74:F3:B6:9F:00:37:B2:4E:D1:54:26:11:58:C8:0F`
  - **Updated Mobile Welcome Dialog** (`lib/presentation/screens/welcome/mobile_welcome_screen.dart`): Replaced previous developer's stale SHA-1 string with this machine's exact active debug keystore SHA-1.
  - **Provided Cloud Console Setup Guide**: Formulated step-by-step instructions for adding the local debug SHA-1 to the Google Cloud / Firebase Console project (`1030532523858`).
- **Files Modified / Created**:
  - `lib/presentation/screens/welcome/mobile_welcome_screen.dart` — Updated hardcoded notice with active machine SHA-1.
  - `MEMORY.md` — Updated with Block 3.
- **Verification & Testing Status**:
  - Verified keystore contents via `keytool.exe`.
  - Confirmed `mobile_welcome_screen.dart` syntax and formatting.
- **Current System State & Immediate Next Steps**:
  - **Current State**: App runs on physical device `moto g73 5G`. Google Sign-In requires registering the SHA-1 in Firebase/Google Cloud Console.
  - **Immediate Next Steps**:
    1. User adds SHA-1 `CC:02:53:FD:0A:82:94:87:7C:AE:8B:9D:77:8A:A3:CE:0E:E1:4F:E9` to Firebase/Google Cloud Console under `com.shaadow.no5ocial`.
    2. Wait 2–3 minutes for Google Play Services propagation.
    3. Re-test "Continue with Google" on the phone.

---

### Block 4 — 2026-10-29 | Analyzer Verification, Test Suite & Remote Sync
- **Timestamp**: 2026-10-29T20:13:00+05:30
- **AI Model**: Gemini 3.8 Flash (High)
- **Agent/Role**: Release & Quality Engineer (Antigravity)
- **Objective / User Request**:
  - "PUSH TO GITHUB"
- **Features Implemented & Architectural Changes**:
  - **Analyzer & Code Health Audit**: Ran `flutter analyze` — passed with 0 errors and 0 warnings across the entire codebase.
  - **Test Suite Verification**: Ran `flutter test` across unit and widget tests (76 tests passed).
  - **Git Remote Synchronization**: Staged and committed `MEMORY.md`, `AGENTS.md`, and updated `mobile_welcome_screen.dart`, followed by git push to remote `origin/main`.
- **Files Modified / Created**:
  - `AGENTS.md` (Modified) — Mandated `MEMORY.md` session continuity protocol and block-wise log format.
  - `MEMORY.md` (Created & Maintained) — Full architectural catalog and chronological Blocks 1–4.
  - `lib/presentation/screens/welcome/mobile_welcome_screen.dart` (Modified) — Updated active machine debug SHA-1 fingerprint.
- **Verification & Testing Status**:
  - `flutter analyze`: No issues found! (0 warnings, 0 errors).
  - `flutter test`: 76 unit and widget tests passing.
- **Current System State & Immediate Next Steps**:
  - **Current State**: Working directory fully committed and pushed to GitHub `origin/main`.
  - **Immediate Next Steps**:
    1. Add SHA-1 `CC:02:53:FD:0A:82:94:87:7C:AE:8B:9D:77:8A:A3:CE:0E:E1:4F:E9` to Firebase/Google Cloud Console for `com.shaadow.no5ocial`.
    2. Continue social platform publishing adapters audit.
