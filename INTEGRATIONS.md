# Social Platform Integration Plan

**Important:** API products, permissions, quotas, account eligibility, and pricing change. Verify official docs and account eligibility before implementation. This file is a planning checklist, not a guarantee of access.

## Integration order
1. Build the common content model and manual handoff first.
2. Pick one platform/account that the team can authorize and test.
3. Complete one end-to-end publish in a staging environment.
4. Add other platforms one at a time based on actual time saved and API access.
5. Add X only after measuring current API cost for the team's expected publishing volume.

## Instagram
- Investigate the current official Instagram API login flow and publishing endpoints.
- Confirm account is eligible (professional Business/Creator where required by the selected flow).
- Confirm required permissions and whether app review/business verification is needed.
- Support only formats explicitly confirmed by current API docs and approved permissions.
- Check media container processing/publishing status where applicable.
- Manual fallback for unsupported formats, personal accounts, or inaccessible permissions.
- Never assume Stories, all Reel formats, or every media feature is supported just because image publishing works.

## YouTube
- Use YouTube Data API OAuth with the minimum scopes needed for uploads.
- Implement resumable upload for large video files where appropriate.
- Support title, description, privacy setting, audience/children designation when applicable, and thumbnail only if permission/API supports it.
- Track upload processing separately from upload acceptance.
- Check current quota allocation and video-upload policy; quota can change and access can require compliance steps.
- Never default a video to public without explicit configuration/confirmation.

## LinkedIn
- **Architecture**: Official versioned Posts API (`POST https://api.linkedin.com/rest/posts`) with protocol version `2.0.0` and LinkedIn-Version `202401`.
- **Member Profile Publishing**:
  - OAuth Scopes: `openid`, `profile`, `email`, `w_member_social`.
  - Author URN: `urn:li:person:{person_id}` from `GET https://api.linkedin.com/v2/userinfo`.
  - Capabilities: `['text', 'image', 'video', 'article', 'commentary', 'member_publishing']`.
- **Organization (Company Page) Publishing**:
  - OAuth Scopes: `openid`, `profile`, `email`, `w_member_social`, `w_organization_social`, `r_organization_social`, `r_organization_admin`, `rw_organization_admin`.
  - Author URN: `urn:li:organization:{organization_id}` from `GET https://api.linkedin.com/rest/organizationAcls?q=roleAssignee`.
  - Requires user to be `ADMINISTRATOR` or `CONTENT_ADMINISTRATOR` on the target organization.
  - Capabilities: `['text', 'image', 'video', 'article', 'commentary', 'organization_publishing', 'analytics']`.
- **Preflight constraints**: Maximum commentary length of 3,000 characters; author URN validation.
- **Ambiguous Outcomes**: Queries `/rest/posts/{postId}` to reconcile timeouts without creating duplicates.


## X
- Review the current official developer API pricing and write endpoint costs before coding.
- Estimate monthly spend: posts × destination accounts × per-request costs, including media-related calls and retries.
- Configure a hard monthly budget/kill switch.
- If API spend is not justified, use manual handoff rather than unofficial endpoints.
- Do not promise zero-cost publishing to X.

## Platform-neutral rules
- Each account must show connection status and supported capabilities.
- Use official OAuth; do not ask users for social passwords.
- Handle token expiry, revoked access, scope changes, rate limits, and API version changes.
- Keep provider error messages sanitized and actionable.
- Maintain a provider integration test checklist and record last verification date.
