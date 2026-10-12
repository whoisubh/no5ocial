# no5ocial — Shaadow Internal Publishing Manager

> **Internal Operations Workflow for Shaadow Multi-Brand Social Publishing**  
> Built with Flutter (Material 3), typed Dart domain models, and server-side publishing interfaces.  
> Designed to replace costly third-party schedulers (saving ₹3,000–₹10,000/month) with high reliability, zero secret leakage, and robust manual handoffs.

---

## 1. System Overview

Shaadow operates multiple brands and social presences across Instagram, YouTube, LinkedIn, and X:
- **Brands:** Shaadow, Shaadow Works, Boofer, Favtunes, Galaxious, Owl & Fowl Studios.
- **Problem:** Commercial social schedulers charge per-account fees (~₹3,000+/month) that are non-viable for early-stage multi-brand studios. Furthermore, generic tools fail silently on platform limits and risk duplicate postings.
- **Solution:** A calm, reliable operations console where creators write once, adapt per destination, preflight against strict platform constraints, publish automatically when supported, and perform rapid 15-second manual handoffs when APIs are restricted or cost-prohibitive.

---

## 2. Architecture & Design

### Visual Aesthetic
- **Tone:** Calm, precise operations console (designed per `DESIGN.md`).
- **Color Palette:**
  - Background: Neutral Soft (`#F7F8FA`)
  - Surfaces: Clean White (`#FFFFFF`) with subtle hairline borders (`#E5E7EB`)
  - Typography: Charcoal (`#17191C`) with muted secondary labels (`#6B7280`)
  - Accent: Restrained Blue (`#3659D9`)
- **Philosophy:** No loud marketing gradients across the application background; clear, high-contrast status chips and actionable checklists.

### Architecture Layers
```text
Flutter Presentation (State / Screens / Widgets)
       │
Application Layer (AppState ChangeNotifier)
       │
Domain Layer (Typed Models, PreflightValidator, PublishingAdapter Interface)
       │
Data Layer (Repositories, Seed Data, StringSanitizer)
       │
Backend / Cloud Boundary (PostgreSQL / Supabase / OAuth Worker)
```

---

## 3. What is Real vs. Mocked vs. Requiring Approval

| Feature / Component | Status | Details |
| :--- | :---: | :--- |
| **Material 3 Operations Console** | **REAL** | 5 core areas: Home, Content Library, Calendar, Accounts Registry, Settings. |
| **Multi-Destination Composer** | **REAL** | Brand picker, multi-account selection, brand mismatch warnings, per-destination caption override tabs, real-time character & hashtag counters. |
| **Preflight Validation Engine** | **REAL** | Verifies character limits (X ≤280, IG ≤2200, YT ≤5000, LI ≤3000), hashtag counts (IG ≤30), required media checks, brand mismatches, and connection states. |
| **Manual Publishing Handoff** | **REAL** | 1-tap clipboard copy, media staging, platform checklist, and live post URL confirmation dialog. Completes in ≤15 seconds. |
| **Independent Job Tracking** | **REAL** | Multi-destination publishes track each platform in isolated job records. Partial failures do not roll back successful destinations. |
| **Ambiguous Timeout Safety** | **REAL** | If a publish times out ambiguously, retry is locked behind explicit duplicate-risk confirmation to protect brand feeds. |
| **Secret Redaction Engine** | **REAL** | `StringSanitizer` automatically redacts OAuth Bearer tokens, query credentials, and authorization headers from logs and error messages. |
| **Timezone Management** | **REAL** | All timestamps stored in strict UTC; rendered dynamically in user-selected timezones (e.g., `Asia/Kolkata`). |
| **Automated Test Suite** | **REAL** | 16 comprehensive unit and widget tests passing with 0 errors and 0 analyzer warnings. |
| **Backend Database Schema** | **REAL** | PostgreSQL DDL (`backend/schema.sql`) with tables, triggers, indexes, and RLS policies, plus portfolio seed data (`backend/seed.sql`). |
| **Publishing Adapter Implementation** | **TEST FAKE** | `FakePublishingAdapter` is strictly labeled as a test fake for UI simulation; no fake API successes are misrepresented as real production calls. |
| **Live Social API Access** | **REQUIRES APPROVAL** | Meta App Review (`instagram_content_publish`), Google OAuth Verification (for YouTube uploads >6/day), LinkedIn Developer Application. |

---

## 4. Recurring Operating Cost Model

Commercial publishing tools typically charge ₹3,000 to ₹10,000/month for multi-brand workspaces. no5ocial's internal architecture slashes this to nearly **₹0**:

| Component | Provider / Service | Monthly Cost | Notes |
| :--- | :--- | :--- | :--- |
| **Database & Auth** | Supabase (Free Tier) | ₹0 / mo | 500MB DB & 1GB file storage (sufficient for initial portfolio metadata). |
| **Instagram API** | Meta Graph API | ₹0 / mo | Up to 25 published posts per 24 hours per account. |
| **YouTube API** | Google Cloud YouTube Data API v3 | ₹0 / mo | 10,000 free quota units/day (~6 video uploads/day). |
| **LinkedIn API** | LinkedIn Community Management | ₹0 / mo | Standard company page posting within rate limits. |
| **X (Twitter)** | **Manual Handoff Flow** | **₹0 / mo** | Avoids the $100/mo (₹8,300/mo) Basic API fee by using no5ocial's 15-second manual copy & confirm flow. |
| **Hosting & Worker** | Self-hosted / Fly.io / Render | ₹0–₹500 / mo | Small Docker container or edge function worker. |
| **Total Monthly Spend** | | **₹0 – ₹500 / month** | **90–95% savings** vs commercial tools. |

---

## 5. Developer Setup & Verification

### Running the App
1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run static analysis (enforces 0 linter issues):
   ```bash
   flutter analyze
   ```

3. Run automated test suite:
   ```bash
   flutter test
   ```

4. Launch application:
   ```bash
   # Desktop Web (Chrome):
   flutter run -d chrome

   # Android Mobile:
   flutter run -d android
   ```

### Backend & OAuth Configuration
- Refer to [`DEVELOPER_SETUP.md`](file:///E:/no5ocial/DEVELOPER_SETUP.md) for step-by-step developer portal guides for Meta, Google, LinkedIn, and X.
- Refer to [`PLATFORM_CAPABILITIES.md`](file:///E:/no5ocial/PLATFORM_CAPABILITIES.md) for the verified platform capability matrix and documentation links.
- Refer to [`backend/.env.example`](file:///E:/no5ocial/backend/.env.example) for required server environment variables.
