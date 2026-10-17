const crypto = require('crypto');

// In-memory cache to prevent double-execution / prefetch code burning on Vercel
const successfulExchanges = new Map();
const inFlightExchanges = new Map();

module.exports = async function handler(req, res) {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0');
  res.setHeader('Pragma', 'no-cache');

  // Ignore HEAD and browser prefetch requests to protect one-time codes
  if (req.method === 'HEAD') return res.status(200).end();
  if (req.headers['purpose'] === 'prefetch' || req.headers['sec-purpose'] === 'prefetch') {
    return res.status(204).end();
  }

  try {
    const { code, state, error: oauthError, error_description } = req.query;

    if (oauthError) {
      return res.status(400).send(renderHtml({
        success: false,
        title: 'Instagram Authorization Cancelled',
        message: error_description || 'You cancelled the Instagram account authorization or denied required publishing permissions.',
        actionText: 'Return to Workspace',
        actionUrl: '/accounts',
      }));
    }

    if (!code) {
      return res.status(400).send(renderHtml({
        success: false,
        title: 'Missing Authorization Code',
        message: 'Instagram did not return an authorization code. Please initiate the link from no5ocial again.',
        actionText: 'Return to Workspace',
        actionUrl: '/accounts',
      }));
    }

    // Clean authorization code: Instagram appends #_ fragment which breaks validation if included
    const cleanCode = code ? String(code).replace(/#_$/, '').split('#')[0].trim() : '';

    // If this code was already successfully exchanged, reuse the cached payload immediately
    if (successfulExchanges.has(cleanCode)) {
      const cached = successfulExchanges.get(cleanCode);
      return res.status(200).send(renderSuccessHtml(cached));
    }

    // Verify HMAC signed state to prevent CSRF
    let brandId = '';
    let returnUrl = '/accounts';
    let stateRedirectUri = null;
    const secret = (
      process.env.INSTAGRAM_APP_SECRET ||
      process.env.META_APP_SECRET ||
      'a6db8aa7b936be95e91015594fc402e5'
    ).trim().replace(/^["']|["']$/g, '');

    if (state) {
      try {
        const decodedState = JSON.parse(Buffer.from(state, 'base64url').toString('utf8'));
        const expectedSig = crypto
          .createHmac('sha256', secret)
          .update(decodedState.payload)
          .digest('hex');

        if (decodedState.sig === expectedSig) {
          const payload = JSON.parse(decodedState.payload);
          brandId = payload.brandId || '';
          returnUrl = payload.returnUrl || '/accounts';
          if (payload.redirectUri) {
            stateRedirectUri = payload.redirectUri;
          }
        }
      } catch (e) {
        console.warn('[Instagram State Verification Warning]', e.message);
      }
    }

    const appId = (
      process.env.INSTAGRAM_APP_ID ||
      process.env.META_APP_ID ||
      process.env.FACEBOOK_APP_ID ||
      '1406614248351632'
    ).trim();

    const appSecret = (
      process.env.INSTAGRAM_APP_SECRET ||
      process.env.META_APP_SECRET ||
      'a6db8aa7b936be95e91015594fc402e5'
    ).trim().replace(/^["']|["']$/g, '');

    let host = req.headers['x-forwarded-host'] || req.headers.host || 'no5ocial.vercel.app';
    if (host.includes(',')) {
      host = host.split(',')[0].trim();
    }
    const proto = req.headers['x-forwarded-proto'] || (host.includes('localhost') ? 'http' : 'https');

    let redirectUri = (
      stateRedirectUri ||
      process.env.INSTAGRAM_REDIRECT_URI ||
      (host.includes('localhost')
        ? `${proto}://${host}/api/auth/callback/instagram`
        : 'https://no5ocial.vercel.app/api/auth/callback/instagram')
    ).trim().replace(/\/+$/, '');

    // 1. Exchange authorization code for short-lived access token
    const tokenFormData = new URLSearchParams({
      client_id: appId,
      client_secret: appSecret,
      grant_type: 'authorization_code',
      redirect_uri: redirectUri,
      code: cleanCode,
    });

    let tokenRes = await fetch('https://api.instagram.com/oauth/access_token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: tokenFormData.toString(),
    });

    let tokenData = await tokenRes.json();
    let fbTokenData = null;

    // If api.instagram.com rejects the code, attempt token exchange via Meta Graph API v21.0
    if (!tokenRes.ok || tokenData.error_type || tokenData.error) {
      try {
        const fbRes = await fetch('https://graph.facebook.com/v21.0/oauth/access_token', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: tokenFormData.toString(),
        });
        fbTokenData = await fbRes.json();
        if (fbRes.ok && fbTokenData.access_token) {
          tokenRes = fbRes;
          tokenData = fbTokenData;
        }
      } catch (fbErr) {
        console.warn('[Meta Graph Token Exchange Warning]', fbErr.message);
      }
    }

    const isSecretFromEnv = Boolean(process.env.INSTAGRAM_APP_SECRET || process.env.META_APP_SECRET);
    if (!tokenRes.ok || tokenData.error_type || tokenData.error) {
      console.error('[Instagram Token Exchange Error]', tokenData);
      return res.status(400).send(renderHtml({
        success: false,
        title: 'Instagram Token Exchange Failed',
        message: tokenData.error_message || tokenData.error?.message || 'Error validating verification code. The authorization code may have expired, redirect_uri must match, or the App Secret is invalid.',
        actionText: 'Authorize Instagram Again',
        actionUrl: `/api/auth/instagram/start?brandId=${encodeURIComponent(brandId)}&returnUrl=/accounts`,
        debugDetails: JSON.stringify({
          redirect_uri_sent: redirectUri,
          client_id: appId,
          secret_source: isSecretFromEnv ? 'configured_in_vercel_environment' : 'fallback_default_secret (may be invalid/expired on Meta)',
          api_instagram_response: tokenData,
          graph_facebook_response: fbTokenData,
          resolution_steps: [
            '1. Verify Instagram App Secret: Go to Meta Dashboard > Your App > Use Cases > Instagram > API setup with Instagram Login — the Instagram App Secret is shown there (it is DIFFERENT from the Facebook App Secret in Settings > Basic).',
            '2. Update Vercel Environment Variables: Add INSTAGRAM_APP_SECRET in Vercel Project Settings > Environment Variables.',
            '3. Check Valid OAuth Redirect URIs in Meta Dashboard under Instagram > Settings: ensure "https://no5ocial.vercel.app/api/auth/callback/instagram" is added byte-for-byte.',
            '4. Fresh Code Required: Never refresh the callback URL. Authorization codes are strictly single-use and expire in 5 minutes.',
          ],
        }, null, 2),
      }));
    }

    const shortLivedToken = tokenData.access_token;
    let igUserId = tokenData.user_id;

    // 2. Exchange short-lived token for long-lived 60-day token
    let longLivedToken = shortLivedToken;
    try {
      const longLivedUrl = `https://graph.instagram.com/access_token?grant_type=ig_exchange_token&client_secret=${encodeURIComponent(appSecret)}&access_token=${encodeURIComponent(shortLivedToken)}`;
      const longLivedRes = await fetch(longLivedUrl);
      if (longLivedRes.ok) {
        const longLivedData = await longLivedRes.json();
        if (longLivedData.access_token) {
          longLivedToken = longLivedData.access_token;
        }
      }
    } catch (e) {
      console.warn('[Instagram Long-Lived Token Exchange Warning]', e.message);
    }

    // 3. Fetch verified Instagram Account details via Instagram Graph API
    let username = 'instagram_creator';
    let name = 'Instagram Creator';
    let avatarUrl = '';
    let accountType = 'BUSINESS';

    try {
      const profileUrl = `https://graph.instagram.com/v21.0/me?fields=user_id,username,name,profile_picture_url,account_type&access_token=${encodeURIComponent(longLivedToken)}`;
      const profileRes = await fetch(profileUrl);
      if (profileRes.ok) {
        const profileData = await profileRes.json();
        igUserId = profileData.user_id || profileData.id || igUserId;
        username = profileData.username || username;
        name = profileData.name || profileData.username || name;
        avatarUrl = profileData.profile_picture_url || '';
        accountType = profileData.account_type || accountType;
      }
    } catch (e) {
      console.warn('[Instagram Profile Fetch Warning]', e.message);
    }

    // If profile not resolved via graph.instagram.com, query graph.facebook.com accounts
    if (username === 'instagram_creator') {
      try {
        const fbAccountsUrl = `https://graph.facebook.com/v21.0/me/accounts?fields=id,name,instagram_business_account{id,username,name,profile_picture_url}&access_token=${encodeURIComponent(longLivedToken)}`;
        const fbAccRes = await fetch(fbAccountsUrl);
        if (fbAccRes.ok) {
          const fbAccData = await fbAccRes.json();
          const page = fbAccData.data?.find(p => p.instagram_business_account);
          if (page && page.instagram_business_account) {
            const ig = page.instagram_business_account;
            igUserId = ig.id || igUserId;
            username = ig.username || username;
            name = ig.name || username;
            avatarUrl = ig.profile_picture_url || '';
          }
        }
      } catch (e) {
        console.warn('[Meta Facebook Accounts Fetch Warning]', e.message);
      }
    }

    const channelPayload = {
      id: String(igUserId || 'ig_' + username),
      title: name,
      handle: username.startsWith('@') ? username : `@${username}`,
      avatarUrl: avatarUrl,
      accountType: accountType,
      platform: 'instagram',
      brandId: brandId,
      accessToken: longLivedToken,
    };

    const successPayload = {
      channel: channelPayload,
      returnUrl: returnUrl,
    };

    if (cleanCode) {
      successfulExchanges.set(cleanCode, successPayload);
      setTimeout(() => successfulExchanges.delete(cleanCode), 300000);
    }

    return res.status(200).send(renderSuccessHtml(successPayload));
  } catch (err) {
    console.error('[Instagram OAuth Callback Exception]', err);
    return res.status(500).send(renderHtml({
      success: false,
      title: 'Server Callback Error',
      message: err.message || 'An unexpected error occurred during Instagram authorization.',
      actionText: 'Return to Workspace',
      actionUrl: '/accounts',
    }));
  }
};

function renderSuccessHtml({ channel, returnUrl }) {
  const safeJson = JSON.stringify(channel).replace(/</g, '\\u003c');
  const appDeepLink = `no5ocial://auth/callback?platform=instagram&channelId=${encodeURIComponent(channel.id)}&channelTitle=${encodeURIComponent(channel.title)}&channelHandle=${encodeURIComponent(channel.handle)}&brandId=${encodeURIComponent(channel.brandId || '')}&accessToken=${encodeURIComponent(channel.accessToken || '')}`;
  const redirectTarget = `${returnUrl}${returnUrl.includes('?') ? '&' : '?'}connected=instagram&channelId=${encodeURIComponent(channel.id)}&channelTitle=${encodeURIComponent(channel.title)}&channelHandle=${encodeURIComponent(channel.handle)}`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Instagram Connected — no5ocial</title>
  <link rel="icon" type="image/png" href="/favicon.png">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: #07090E;
      color: #F8FAFC;
      font-family: 'Inter', -apple-system, sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    .container {
      max-width: 520px;
      width: 100%;
      background: #0F1420;
      border: 1px solid #1E293B;
      border-radius: 20px;
      padding: 40px 32px;
      text-align: center;
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
    }
    .brand-logo {
      height: 28px;
      margin-bottom: 24px;
    }
    .icon-badge {
      width: 64px;
      height: 64px;
      border-radius: 50%;
      background: linear-gradient(45deg, #F58529, #DD2A7B, #8134AF, #515BD4);
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 20px;
      box-shadow: 0 10px 25px rgba(221, 42, 123, 0.35);
    }
    .icon-badge svg {
      width: 34px;
      height: 34px;
      fill: #FFFFFF;
    }
    h1 {
      font-size: 24px;
      font-weight: 800;
      margin-bottom: 8px;
      color: #FFFFFF;
    }
    .subtitle {
      font-size: 14px;
      color: #94A3B8;
      margin-bottom: 28px;
      line-height: 1.5;
    }
    .channel-card {
      background: #182234;
      border: 1px solid #334155;
      border-radius: 14px;
      padding: 16px;
      display: flex;
      align-items: center;
      text-align: left;
      margin-bottom: 28px;
    }
    .avatar {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      background: #334155;
      margin-right: 14px;
      object-fit: cover;
    }
    .avatar-fallback {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      background: linear-gradient(135deg, #E1306C, #833AB4);
      color: white;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 700;
      font-size: 18px;
      margin-right: 14px;
    }
    .channel-info h3 {
      font-size: 15px;
      font-weight: 700;
      color: #FFFFFF;
      margin-bottom: 2px;
    }
    .channel-info p {
      font-size: 13px;
      color: #E1306C;
      font-weight: 500;
    }
    .btn-primary {
      display: block;
      width: 100%;
      background: linear-gradient(135deg, #E1306C, #C13584);
      color: #FFFFFF;
      text-decoration: none;
      font-weight: 600;
      font-size: 15px;
      padding: 14px;
      border-radius: 12px;
      transition: all 0.2s ease;
      cursor: pointer;
      border: none;
    }
    .btn-primary:hover {
      opacity: 0.95;
      transform: translateY(-1px);
    }
    .footer-note {
      margin-top: 20px;
      font-size: 12px;
      color: #64748B;
    }
  </style>
</head>
<body>
  <div class="container">
    <img src="/assets/logo/no5ocial_white.png" alt="no5ocial" class="brand-logo" onerror="this.style.display='none'">
    <div class="icon-badge">
      <svg viewBox="0 0 24 24"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/></svg>
    </div>
    <h1>Instagram Connected!</h1>
    <p class="subtitle">Your Instagram account is successfully linked and verified via Meta Graph API.</p>

    <div class="channel-card">
      ${channel.avatarUrl ? `<img src="${channel.avatarUrl}" class="avatar" alt="Avatar">` : `<div class="avatar-fallback">${channel.title.charAt(0)}</div>`}
      <div class="channel-info">
        <h3>${channel.title}</h3>
        <p>${channel.handle} • ${channel.accountType}</p>
      </div>
    </div>

    <a href="${appDeepLink}" id="returnAppBtn" class="btn-primary">Return to no5ocial App</a>
    <a href="${redirectTarget}" id="webBtn" style="display:inline-block; margin-top:14px; color:#94A3B8; text-decoration:underline; font-size:13px; font-weight:500;">Open in Web Browser</a>
    <p class="footer-note" style="margin-top:16px;">Tapping "Return to no5ocial App" will automatically sync this channel to your workspace.</p>
  </div>

  <script>
    const channelData = ${safeJson};
    try {
      localStorage.setItem('no5ocial_linked_channel', JSON.stringify(channelData));
      if (window.opener) {
        window.opener.postMessage({ type: 'NO5OCIAL_CHANNEL_CONNECTED', channel: channelData }, '*');
      }
    } catch (e) {}

    // Automatically trigger app deep link on launch
    try {
      window.location.href = "${appDeepLink}";
    } catch (e) {}
  </script>
</body>
</html>`;
}

function renderHtml({ success, title, message, actionText, actionUrl, debugDetails }) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} — no5ocial</title>
  <link rel="icon" type="image/png" href="/favicon.png">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    body {
      margin: 0;
      background: #0B0F19;
      color: #E2E8F0;
      font-family: 'Inter', -apple-system, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
    }
    .card {
      background: #121827;
      border: 1px solid #1F2937;
      border-radius: 16px;
      max-width: 480px;
      width: 100%;
      padding: 36px 32px;
      text-align: center;
    }
    .badge {
      display: inline-block;
      background: ${success ? 'rgba(16, 185, 129, 0.15)' : 'rgba(239, 68, 68, 0.15)'};
      color: ${success ? '#10B981' : '#EF4444'};
      font-weight: 600;
      font-size: 13px;
      padding: 4px 12px;
      border-radius: 999px;
      margin-bottom: 20px;
    }
    h1 { font-size: 22px; font-weight: 700; margin: 0 0 12px; color: #FFFFFF; }
    p { font-size: 14px; line-height: 1.6; color: #94A3B8; margin: 0 0 24px; }
    .btn {
      display: inline-block;
      background: #3865F6;
      color: #FFFFFF;
      font-weight: 600;
      padding: 12px 24px;
      border-radius: 10px;
      text-decoration: none;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">${success ? 'Success' : 'Authorization Notice'}</div>
    <h1>${title}</h1>
    <p>${message}</p>
    <a href="${actionUrl}" class="btn">${actionText}</a>
    <a href="no5ocial://auth/callback?error=cancelled" style="display:block; margin-top:16px; color:#94A3B8; text-decoration:underline; font-size:13px;">Return to no5ocial App</a>
    ${debugDetails ? `
    <details style="margin-top:20px; text-align:left; background:#07090E; border:1px solid #1F2937; border-radius:8px; padding:12px; font-size:12px; color:#94A3B8; max-height:220px; overflow-y:auto;">
      <summary style="cursor:pointer; color:#E1306C; font-weight:600;">Technical Diagnostics</summary>
      <pre style="white-space:pre-wrap; word-break:break-all; margin-top:8px; font-size:11px;">${debugDetails.replace(/</g, '&lt;')}</pre>
    </details>` : ''}
  </div>
</body>
</html>`;
}
