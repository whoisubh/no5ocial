# Developer Setup & Official OAuth Credentials Guide

> **Security Guardrail:** Never paste secrets, client secrets, access tokens, or service keys into AI chats, commit them to git, or embed them in Flutter client source. All sensitive credentials belong exclusively in secure server-side environment variables or secrets managers.

---

## 1. Prerequisites Checklist
- [ ] Flutter SDK (v3.24+ / Dart 3.5+) installed and verified via `flutter doctor`.
- [ ] PostgreSQL 15+ database or Supabase project.
- [ ] Registered business accounts for Shaadow across target platforms.

---

## 2. Meta for Developers (Instagram Graph API)

### Step 1: Create Meta App
1. Go to [Meta for Developers](https://developers.facebook.com/) and log in with your primary business administrator account.
2. Click **My Apps** → **Create App**.
3. Select **Other** → **Business** as the app type.
4. Enter App Name (e.g., `Shaadow No5ocial Publisher`) and link your Meta Business Account.

### Step 2: Add Products & Permissions
1. In the App Dashboard, add **Instagram Graph API** and **Facebook Login for Business**.
2. Under **Facebook Login Settings**, set:
   - **Valid OAuth Redirect URIs:** `https://api.yourdomain.com/auth/callback/meta` (or `http://localhost:8080/auth/callback/meta` for local dev).
3. Under **App Review > Permissions and Features**, request the following scopes:
   - `instagram_basic`: Read profile info and account IDs.
   - `instagram_content_publish`: Upload media containers and publish to feed/reels.
   - `pages_show_list`: Enumerate Facebook pages connected to the user.
   - `pages_read_engagement`: Verify page link status.

### Step 3: Account Linking
1. Ensure your Instagram account is switched to **Professional (Business or Creator)**.
2. Link the Instagram account to a published **Facebook Page** under Facebook Page Settings > Linked Accounts.

### Step 4: Environment Variables (Server Only)
```bash
META_APP_ID="your_meta_app_id"
META_APP_SECRET="your_meta_app_secret"
META_REDIRECT_URI="https://api.yourdomain.com/auth/callback/meta"
```

---

## 3. Google Cloud Console (YouTube Data API v3)

### Step 1: Create Project & Enable API
1. Navigate to [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project: `shaadow-no5ocial`.
3. Go to **APIs & Services > Library**, search for **YouTube Data API v3**, and click **Enable**.

### Step 2: Configure OAuth Consent Screen
1. Go to **APIs & Services > OAuth consent screen**.
2. Select **External** (or **Internal** if using Google Workspace).
3. Fill in App Name, User support email, and Developer contact information.
4. Under **Scopes**, add:
   - `https://www.googleapis.com/auth/youtube.upload`
   - `https://www.googleapis.com/auth/youtube.readonly`
5. Under **Test Users**, add the Google email accounts associated with Shaadow YouTube channels.

### Step 3: Generate OAuth 2.0 Credentials
1. Go to **APIs & Services > Credentials** → **Create Credentials** → **OAuth client ID**.
2. Application type: **Web application**.
3. Name: `No5ocial YouTube Client`.
4. Authorized redirect URIs:
   - `https://api.yourdomain.com/auth/callback/google`
   - `http://localhost:8080/auth/callback/google`
5. Copy the generated `Client ID` and `Client Secret`.

### Step 4: Environment Variables (Server Only)
```bash
GOOGLE_CLIENT_ID="your_google_client_id.apps.googleusercontent.com"
GOOGLE_CLIENT_SECRET="your_google_client_secret"
GOOGLE_REDIRECT_URI="https://api.yourdomain.com/auth/callback/google"
```

---

## 4. LinkedIn Developer Portal

### Step 1: Create LinkedIn App
1. Go to [LinkedIn Developer Portal](https://www.linkedin.com/developers/).
2. Click **Create App**.
3. App name: `Shaadow No5ocial Publisher`.
4. Associate the app with your verified **Shaadow Platforms** LinkedIn Page.

### Step 2: Request Products
1. Under the **Products** tab, request:
   - **Share on LinkedIn** (for personal profile posts).
   - **Community Management API** (for publishing to Shaadow Platforms company page).
2. Note: Access to Community Management API requires LinkedIn review or standard partner onboarding.

### Step 3: Configure Auth & Redirects
1. Under the **Auth** tab, add your redirect URIs:
   - `https://api.yourdomain.com/auth/callback/linkedin`
2. Ensure requested scopes include:
   - `w_member_social`
   - `w_organization_social`
   - `r_organization_social`

### Step 4: Environment Variables (Server Only)
```bash
LINKEDIN_CLIENT_ID="your_linkedin_client_id"
LINKEDIN_CLIENT_SECRET="your_linkedin_client_secret"
LINKEDIN_REDIRECT_URI="https://api.yourdomain.com/auth/callback/linkedin"
```

---

## 5. X (Twitter) Developer Portal

### Step 1: App Setup
1. Log in to [X Developer Portal](https://developer.x.com/).
2. Under **Projects & Apps**, create a new project and app.
3. Under **User authentication settings**, click **Set up**:
   - App permissions: **Read and write**.
   - Type of App: **Confidential client** (or Public client with PKCE).
   - Callback URI: `https://api.yourdomain.com/auth/callback/x`.
   - Website URL: `https://shaadow.in`.

### Step 2: Pricing & Quota Awareness
- **Free Tier:** 1,500 tweets/month at app level. Media upload can encounter restrictions.
- **Basic Tier:** $100/month.
- **No5ocial Standard:** Because No5ocial prioritizes minimal operating expenses, use the **Manual Publishing Handoff** flow for X posts until publishing volume warrants the $100/month API fee.

---

## 6. Database & Backend Initialization

### 1. Execute SQL Schema
If using PostgreSQL / Supabase, run the migration script:
```bash
psql -h your_db_host -U postgres -d no5ocial -f backend/schema.sql
psql -h your_db_host -U postgres -d no5ocial -f backend/seed.sql
```

### 2. Configure Local `.env`
Copy `backend/.env.example` to `backend/.env` and populate database credentials.

---

## 7. Running the Flutter Client Locally

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run code analysis (must pass with 0 issues):
   ```bash
   flutter analyze
   ```

3. Run automated tests (16 unit & widget tests):
   ```bash
   flutter test
   ```

4. Launch the application:
   ```bash
   # On Chrome (Desktop Web):
   flutter run -d chrome

   # On Connected Android Device or Emulator:
   flutter run -d android

   # On Windows Desktop:
   flutter run -d windows
   ```
