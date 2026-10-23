# Social Platform Integrations & Developer Setup Guide

> **Security Guardrail:** Never paste secrets, client secrets, access tokens, or service keys into client code or git. All sensitive credentials belong exclusively in secure server-side environment variables or secret managers per `SECURITY.md`.

---

## 1. Cross-Platform Capability Matrix

| Platform | Text Only | Single Image | Carousel | Video / Reels / Shorts | Alt Text | First Comment | Scheduled Publish | Pricing / Quota Limits | Verified Docs |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Instagram** (Business / Creator) | ❌ Blocked | ✅ Supported | ✅ Supported (2-10 items) | ✅ Supported (Reels & Feed) | ✅ Supported | ⚠️ Via 2-step Graph API | ✅ Server-side | Free (25 published posts / 24h / account) | [Meta Content Publishing API](https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/content-publishing) |
| **YouTube** | ❌ Blocked | ❌ Blocked | ❌ Blocked | ✅ Supported (Videos & Shorts) | ❌ N/A | ❌ Separate Comments API | ✅ Native scheduled privacy status | Free (10,000 units/day default; 1,600 units/upload = ~6 vids/day) | [YouTube Data API v3 Upload](https://developers.google.com/youtube/v3/guides/uploading_a_video) |
| **LinkedIn** (Company Pages) | ✅ Supported | ✅ Supported | ❌ PDF Doc only | ✅ Supported (MP4/H.264) | ✅ Supported | ❌ Not in Posts API | ✅ Server-side | Free (100 posts/day/org) | [LinkedIn Posts API](https://learn.microsoft.com/en-us/linkedin/marketing/community-management/shares/posts-api) |
| **X (Twitter)** | ✅ Supported | ✅ Supported (up to 4) | ❌ Grid only | ✅ Supported (up to 512MB) | ✅ Supported | ⚠️ Via reply_id | ✅ Server-side | **Paid ($100/mo Basic)** / Free write heavily throttled | [X API v2 Post Tweet](https://developer.x.com/en/docs/x-api/tweets/manage-tweets/api-reference/post-tweets) |
| **Facebook** (Pages) | ✅ Supported | ✅ Supported | ✅ Supported | ✅ Supported | ✅ Supported | ⚠️ Via Graph API | ✅ Native & Server-side | Free (Standard Graph API rate limits) | [Meta Graph API Pages](https://developers.facebook.com/docs/pages-api/posts) |
| **Threads** | ✅ Supported | ✅ Supported | ✅ Supported | ✅ Supported | ✅ Supported | ⚠️ Via reply_id | ✅ Server-side | Free (250 posts/day rate limit) | [Threads API Publishing](https://developers.facebook.com/docs/threads/posts) |

---

## 2. Platform-Specific Publishing Details

### 1. Instagram Graph API
- **Official Documentation:** [Meta Content Publishing API](https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/content-publishing)
- **Account Eligibility:** Must be an **Instagram Professional Account** (Business or Creator) linked to a **Facebook Page** where the developer has Admin access.
- **Required Scopes:** `instagram_basic`, `instagram_content_publish`, `pages_show_list`, `pages_read_engagement`.
- **Publishing Flow:**
  1. POST to `/{ig-user-id}/media` with `image_url` or `video_url` to create container.
  2. Poll `/{ig-container-id}?fields=status_code` until `FINISHED`.
  3. POST to `/{ig-user-id}/media_publish` with `creation_id={ig-container-id}`.
- **Constraints:** Caption ≤ 2,200 chars, hashtags ≤ 30. Text-only posts are rejected. Rate limit: 25 published posts per rolling 24 hours.

### 2. YouTube Data API v3
- **Official Documentation:** [YouTube API Video Upload Guide](https://developers.google.com/youtube/v3/guides/uploading_a_video)
- **Account Eligibility:** Google Account with phone-verified YouTube Channel for uploads >15 mins.
- **Required Scopes:** `https://www.googleapis.com/auth/youtube.upload`, `https://www.googleapis.com/auth/youtube.readonly`.
- **Publishing Flow:** Initiate resumable upload session (POST), stream chunks (PUT), poll `processingDetails` until `processed`.
- **Constraints:** Title ≤ 100 chars, description ≤ 5,000 chars. Privacy: `private`, `unlisted`, `public`. Quota cost: 1,600 units per upload. Scheduled publishing supported natively via `publishAt` with `privacyStatus: 'private'`.

### 3. LinkedIn Posts API
- **Official Documentation:** [LinkedIn Community Management Posts API](https://learn.microsoft.com/en-us/linkedin/marketing/community-management/shares/posts-api)
- **Account Eligibility:** Company Page where member holds `ADMINISTRATOR` or `CONTENT_CURATOR` role, or personal member profile.
- **Required Scopes:** `w_member_social`, `w_organization_social`, `r_organization_social`.
- **Constraints:** Text commentary ≤ 3,000 chars. Media initialization requires a two-step handshake via `/rest/images?action=initializeUpload` or `/rest/videos?action=initializeUpload`.

### 4. X (Twitter) Developer API v2
- **Official Documentation:** [X API v2 Manage Tweets](https://developer.x.com/en/docs/x-api/tweets/manage-tweets/api-reference/post-tweets)
- **Required Scopes:** `tweet.read`, `tweet.write`, `users.read`, `offline.access`.
- **Pricing & Fallback:** Free tier is throttled (1,500 app writes/month). Basic tier costs $100/mo. To keep operating expenses at ₹0, no5ocial implements **Manual Publishing Handoff for X** by default.

---

## 3. Developer Portal & OAuth Setup

### Meta for Developers (Instagram & Facebook)
1. Go to [Meta for Developers](https://developers.facebook.com/) → **My Apps** → **Create App** (Type: Business).
2. Add **Instagram Graph API** and **Facebook Login for Business**.
3. Under **Facebook Login Settings**, set valid OAuth redirect URI: `https://your-domain.com/api/auth/callback/meta`.
4. Environment Variables (Server only):
   ```bash
   META_APP_ID="your_meta_app_id"
   META_APP_SECRET="your_meta_app_secret"
   META_REDIRECT_URI="https://your-domain.com/api/auth/callback/meta"
   ```

### Google Cloud Console (YouTube Data API v3 & Google Auth)
1. Go to [Google Cloud Console](https://console.cloud.google.com/) and enable **YouTube Data API v3**.
2. Configure OAuth Consent Screen with scopes `youtube.upload` and `youtube.readonly`.
3. Under **Credentials**, create OAuth 2.0 Web Client ID with authorized redirect URI: `https://your-domain.com/api/auth/callback/google`.
4. Environment Variables:
   ```bash
   GOOGLE_CLIENT_ID="your_client_id.apps.googleusercontent.com"
   GOOGLE_CLIENT_SECRET="your_google_client_secret"
   GOOGLE_REDIRECT_URI="https://your-domain.com/api/auth/callback/google"
   ```

### LinkedIn Developer Portal
1. Go to [LinkedIn Developers](https://www.linkedin.com/developers/) → **Create App**.
2. Request **Share on LinkedIn** and **Community Management API** products.
3. Under **Auth**, configure redirect URI: `https://your-domain.com/api/auth/callback/linkedin`.
4. Environment Variables:
   ```bash
   LINKEDIN_CLIENT_ID="your_linkedin_client_id"
   LINKEDIN_CLIENT_SECRET="your_linkedin_client_secret"
   LINKEDIN_REDIRECT_URI="https://your-domain.com/api/auth/callback/linkedin"
   ```

---

## 4. Manual Publishing Handoff Standard

When an official API route is restricted, pending review, cost-prohibitive (e.g. X at $100/mo), or format-unsupported (e.g. Instagram text-only), no5ocial immediately routes the post variant to **Manual Publishing Handoff**:

1. **1-Tap Clipboard Copy:** Formatted, platform-tailored caption with hashtag block copied to clipboard.
2. **Media Staging:** Export media assets to device camera roll / file system via OS share sheet.
3. **Platform Launch:** Launch target social application on device.
4. **Outcome Confirmation:** User confirms with live public post URL.
5. **Auditing:** System records status as `published (manual)` with post URL, never misrepresenting manual execution as automated API delivery.
