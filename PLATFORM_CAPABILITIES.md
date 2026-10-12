# Social Platform Capabilities Matrix & Official API Analysis

> **Last Verified Date:** October 2026  
> **Status:** Authoritative reference for no5ocial publishing orchestrator and preflight validation engine.  
> **Rule:** Never fabricate API capabilities. If an official API route is restricted, unapproved, or cost-prohibitive, fall back to **Manual Publishing Handoff** with full status clarity.

---

## 1. Cross-Platform Capability Matrix

| Platform | Text Only | Single Image | Carousel | Video / Reels / Shorts | Alt Text | First Comment | Scheduled Publish | Pricing / Quota Limits | Verified Doc Link |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Instagram** (Business / Creator) | ❌ Blocked | ✅ Supported | ✅ Supported (2-10 items) | ✅ Supported (Reels & Feed) | ✅ Supported | ⚠️ Via 2-step Graph API | ✅ Server-side | Free (25 published posts per 24h per account) | [Meta Content Publishing API](https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/content-publishing) |
| **YouTube** | ❌ Blocked | ❌ Blocked | ❌ Blocked | ✅ Supported (Videos & Shorts) | ❌ N/A | ❌ Separate Comments API | ✅ Native scheduled privacy status | Free (10,000 units/day default; 1,600 units per upload = ~6 vids/day) | [YouTube Data API v3 Upload](https://developers.google.com/youtube/v3/guides/uploading_a_video) |
| **LinkedIn** (Company Pages) | ✅ Supported | ✅ Supported | ❌ PDF Doc only | ✅ Supported (MP4/H.264) | ✅ Supported | ❌ Not in Posts API | ✅ Server-side | Free (Standard rate limits: 100 posts/day/org) | [LinkedIn Posts API](https://learn.microsoft.com/en-us/linkedin/marketing/community-management/shares/posts-api) |
| **X (Twitter)** | ✅ Supported | ✅ Supported (up to 4) | ❌ Grid only | ✅ Supported (up to 512MB) | ✅ Supported | ⚠️ Via reply_id | ✅ Server-side | **Paid ($100/mo Basic)** / Free write tier heavily throttled | [X API v2 Post Tweet](https://developer.x.com/en/docs/x-api/tweets/manage-tweets/api-reference/post-tweets) |
| **Facebook** (Pages) | ✅ Supported | ✅ Supported | ✅ Supported | ✅ Supported | ✅ Supported | ⚠️ Via Graph API | ✅ Native & Server-side | Free (Standard Graph API rate limits) | [Meta Graph API Pages](https://developers.facebook.com/docs/pages-api/posts) |
| **TikTok** | ❌ Blocked | ✅ Photo mode | ✅ Supported | ✅ Direct Post API | ❌ N/A | ❌ Blocked | ⚠️ Partner tier | Free API (Requires Direct Post Audit & Approval) | [TikTok Direct Post API](https://developers.tiktok.com/doc/content-posting-api-get-started) |
| **Threads** | ✅ Supported | ✅ Supported | ✅ Supported | ✅ Supported | ✅ Supported | ⚠️ Via reply_id | ✅ Server-side | Free (250 posts/day rate limit) | [Threads API Publishing](https://developers.facebook.com/docs/threads/posts) |

---

## 2. Detailed Platform Requirements & Limits

### 1. Instagram Graph API
- **Official Documentation:** [Meta Content Publishing API](https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/content-publishing)
- **Account Eligibility:**
  - Must be an **Instagram Professional Account** (Business or Creator).
  - Must be linked to a **Facebook Page** where the developer has Admin access.
  - Personal Instagram accounts **cannot** use the Content Publishing API.
- **Prerequisite Permissions:**
  - `instagram_basic`
  - `instagram_content_publish`
  - `pages_show_list`
  - `pages_read_engagement`
- **Technical Publishing Flow:**
  1. POST to `/{ig-user-id}/media` with `image_url` or `video_url` (must be a publicly accessible URL) to create a container.
  2. Poll `/{ig-container-id}?fields=status_code` until `FINISHED`.
  3. POST to `/{ig-user-id}/media_publish` with `creation_id={ig-container-id}`.
- **Constraints & Edge Cases:**
  - Caption maximum: 2,200 characters.
  - Hashtags maximum: 30 tags (exceeding causes API error).
  - Text-only posts are strictly rejected by the API.
  - Rate limit: 25 published posts per rolling 24-hour window per account.
  - Media URLs must reside on public HTTPS storage (short-lived signed URLs with minimum 15 minutes TTL).

---

### 2. YouTube Data API v3
- **Official Documentation:** [YouTube API Video Upload Guide](https://developers.google.com/youtube/v3/guides/uploading_a_video)
- **Account Eligibility:**
  - Google Account with a created YouTube Channel.
  - Channel must be phone-verified for videos >15 minutes or custom thumbnails.
- **Prerequisite OAuth Scopes:**
  - `https://www.googleapis.com/auth/youtube.upload`
- **Technical Publishing Flow:**
  1. Initiate resumable upload session: POST to `https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status`.
  2. Stream video chunks (PUT) to the returned `Location` header.
  3. Poll `processingDetails` until video state is `processed`.
- **Constraints & Quota Realities:**
  - Title maximum: 100 characters.
  - Description maximum: 5,000 characters.
  - Privacy status options: `private`, `unlisted`, `public`.
  - **Quota Cost:** An upload costs **1,600 units**. The free tier provides 10,000 quota units per day. This permits only **~6 video uploads per day** across the entire project unless a quota extension is granted by Google Cloud compliance.
  - Automatic scheduled publishing is natively supported by sending `status.publishAt` in RFC 3339 format with `privacyStatus: 'private'`.

---

### 3. LinkedIn Posts API
- **Official Documentation:** [LinkedIn Community Management Posts API](https://learn.microsoft.com/en-us/linkedin/marketing/community-management/shares/posts-api)
- **Account Eligibility:**
  - Organization Company Page where the authenticated member holds the `ADMINISTRATOR` or `CONTENT_CURATOR` role.
  - Personal member profile for personal posts.
- **Prerequisite Permissions:**
  - `w_member_social` (Personal profile sharing)
  - `w_organization_social` (Company page sharing)
  - `r_organization_social` (To query published posts and verification)
- **Constraints & Format Rules:**
  - Text commentary limit: 3,000 characters.
  - Media initialization requires a two-step handshake via `/rest/images?action=initializeUpload` or `/rest/videos?action=initializeUpload`.
  - Native multi-image carousels are deprecated on LinkedIn; multi-slide documents require uploading a PDF document.

---

### 4. X (Twitter) Developer API v2
- **Official Documentation:** [X API v2 Manage Tweets](https://developer.x.com/en/docs/x-api/tweets/manage-tweets/api-reference/post-tweets)
- **Account Eligibility:**
  - Developer portal project with User Authentication Settings enabled (OAuth 2.0 with PKCE).
- **Prerequisite Permissions:**
  - `tweet.read`, `tweet.write`, `users.read`, `offline.access`
- **Pricing & Practical Constraints:**
  - **Free Tier:** Restricted to 1,500 post writes per month at the app level (500 posts/month per authenticated user). Media upload endpoints (`upload.twitter.com/1.1/media/upload.json`) may experience unpredictable tier blocks.
  - **Basic Tier:** Costs **$100 USD/month (~₹8,300/month)**.
  - **Pragmatic Decision for Shaadow:** Because no5ocial targets low operating costs (₹0–₹2,000/mo total), **we implement Manual Publishing Handoff for X** by default. Users can copy the optimized ≤280 character text, export media to the clipboard/gallery, and confirm with live URL in under 15 seconds without paying $100/mo for an API subscription.

---

## 3. Manual Publishing Handoff Fallback Standard

When any of the following conditions occur, no5ocial immediately routes the post variant to **Manual Publishing Handoff**:

1. **Unapproved API Status:** Developer app is pending Meta App Review, Google Quota Audit, or LinkedIn verification.
2. **Unsupported Format:** User attempts an Instagram text-only post, a YouTube image post, or an unauthenticated profile story.
3. **Cost Inefficiency:** Automated posting to platforms like X that charge hundreds of dollars for API write access when the company's volume does not justify the fee.
4. **Token Expiration / Invalidation:** The account's OAuth refresh token expired and the user needs to publish urgently before re-authenticating.

### Manual Handoff Workflow (15-Second SLA):
1. **1-Tap Clipboard Copy:** Formatted, platform-tailored caption with hashtag block copied to OS clipboard.
2. **Media Staging:** Export media assets to device camera roll / file system via OS share sheet.
3. **Platform Deep-Link / Launch:** Launch target social app directly on device.
4. **Outcome Confirmation:** User returns, clicks **Confirm Publication**, and enters the live public post URL.
5. **Auditing:** System logs the post as `published (manual)` with verified post URL, never misrepresenting manual execution as automated API delivery.
