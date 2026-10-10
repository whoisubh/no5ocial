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
- Distinguish member profile posts from organization page posts.
- Confirm access to Share on LinkedIn and any organization/community-management product and permissions needed.
- Confirm the authenticated user has the required organization role.
- Implement supported text/image/video/document formats only after validating current Posts API docs.
- Treat company-page access as a separate capability from personal posting.

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
