const crypto = require('crypto');

// In-memory cache to prevent double-execution / prefetch code burning on Vercel
const successfulExchanges = new Map();

module.exports = async function handler(req, res) {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0');
  res.setHeader('Pragma', 'no-cache');

  // Ignore HEAD and browser prefetch requests
  if (req.method === 'HEAD') return res.status(200).end();
  if (req.headers['purpose'] === 'prefetch' || req.headers['sec-purpose'] === 'prefetch') {
    return res.status(204).end();
  }

  try {
    const { code, state, error: oauthError, error_description } = req.query;

    if (oauthError) {
      return res.status(400).send(renderHtml({
        success: false,
        title: 'X Authorization Cancelled',
        message: error_description || 'You cancelled the X (Twitter) authorization or denied requested publishing permissions.',
        actionText: 'Return to Workspace',
        actionUrl: '/accounts',
      }));
    }

    if (!code) {
      return res.status(400).send(renderHtml({
        success: false,
        title: 'Missing Authorization Code',
        message: 'X did not return an authorization code. Please initiate the link from no5ocial again.',
        actionText: 'Return to Workspace',
        actionUrl: '/accounts',
      }));
    }

    const cleanCode = code ? String(code).replace(/#_$/, '').split('#')[0].trim() : '';

    if (successfulExchanges.has(cleanCode)) {
      const cached = successfulExchanges.get(cleanCode);
      return res.status(200).send(renderSuccessHtml(cached));
    }

    const clientId = (
      process.env.X_CLIENT_ID ||
      process.env.TWITTER_CLIENT_ID ||
      process.env.X_CONSUMER_KEY ||
      ''
    ).trim();

    const clientSecret = (
      process.env.X_CLIENT_SECRET ||
      process.env.TWITTER_CLIENT_SECRET ||
      process.env.X_CONSUMER_SECRET ||
      ''
    ).trim().replace(/^["']|["']$/g, '');

    if (!clientId || !clientSecret) {
      return res.status(500).send(renderHtml({
        success: false,
        title: 'Server Configuration Error',
        message: 'X_CLIENT_ID and/or X_CLIENT_SECRET are not configured in Vercel environment variables.',
        actionText: 'Return to Workspace',
        actionUrl: '/accounts',
      }));
    }

    let brandId = '';
    let accountType = 'standard';
    let returnUrl = '/accounts';
    let codeVerifier = '';
    let stateRedirectUri = null;

    if (state) {
      try {
        const decodedState = JSON.parse(Buffer.from(state, 'base64url').toString('utf8'));
        const expectedSig = crypto
          .createHmac('sha256', clientSecret)
          .update(decodedState.payload)
          .digest('hex');

        if (decodedState.sig === expectedSig) {
          const payload = JSON.parse(decodedState.payload);
          brandId = payload.brandId || '';
          accountType = (payload.accountType || 'standard').toLowerCase();
          returnUrl = payload.returnUrl || '/accounts';
          codeVerifier = payload.codeVerifier || '';
          if (payload.redirectUri) {
            stateRedirectUri = payload.redirectUri;
          }
        }
      } catch (e) {
        console.warn('[X State Verification Warning]', e.message);
      }
    }

    let host = req.headers['x-forwarded-host'] || req.headers.host || 'no5ocial.vercel.app';
    if (host.includes(',')) {
      host = host.split(',')[0].trim();
    }
    const proto = req.headers['x-forwarded-proto'] || (host.includes('localhost') ? 'http' : 'https');

    const redirectUri = (
      stateRedirectUri ||
      process.env.X_REDIRECT_URI ||
      process.env.TWITTER_REDIRECT_URI ||
      (host.includes('localhost')
        ? `${proto}://${host}/api/auth/callback/x`
        : 'https://no5ocial.vercel.app/api/auth/callback/x')
    ).trim().replace(/\/+$/, '');

    // Exchange authorization code + PKCE code_verifier for access token
    const tokenParams = new URLSearchParams({
      grant_type: 'authorization_code',
      code: cleanCode,
      redirect_uri: redirectUri,
      code_verifier: codeVerifier,
    });

    const basicAuth = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

    const tokenResponse = await fetch('https://api.x.com/2/oauth2/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': `Basic ${basicAuth}`,
        'Accept': 'application/json',
      },
      body: tokenParams.toString(),
    });

    const tokenData = await tokenResponse.json();

    if (!tokenResponse.ok || !tokenData.access_token) {
      console.error('[X Token Exchange Error]', tokenData);
      return res.status(400).send(renderHtml({
        success: false,
        title: 'Token Exchange Failed',
        message: tokenData.error_description || tokenData.error || 'Failed to exchange authorization code for X access token.',
        actionText: 'Retry Connection',
        actionUrl: `/api/auth/x/start?brandId=${encodeURIComponent(brandId)}&accountType=${encodeURIComponent(accountType)}`,
      }));
    }

    const accessToken = tokenData.access_token;

    // Fetch authenticated user profile: GET https://api.x.com/2/users/me
    const userResponse = await fetch('https://api.x.com/2/users/me?user.fields=profile_image_url,username,name,verified_type', {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Accept': 'application/json',
      },
    });

    if (!userResponse.ok) {
      const userErr = await userResponse.text();
      console.error('[X User Profile Error]', userErr);
      return res.status(400).send(renderHtml({
        success: false,
        title: 'Failed to Fetch Profile',
        message: 'Could not fetch your X profile details from Twitter API v2.',
        actionText: 'Retry Connection',
        actionUrl: `/api/auth/x/start?brandId=${encodeURIComponent(brandId)}`,
      }));
    }

    const userPayload = await userResponse.json();
    const userData = userPayload.data || {};

    const userId = userData.id || 'x_account';
    const userName = userData.name || 'X User';
    const rawUsername = userData.username || 'user';
    const userHandle = rawUsername.startsWith('@') ? rawUsername : `@${rawUsername}`;
    const avatarUrl = userData.profile_image_url || '';
    const isPremium = Boolean(userData.verified_type) || accountType === 'premium';
    const resolvedAccountType = isPremium ? 'PREMIUM' : 'STANDARD';
    const subtype = isPremium ? 'x_premium' : 'x_profile';

    const channelPayload = {
      id: userId,
      title: userName,
      handle: userHandle,
      avatarUrl: avatarUrl,
      accountType: resolvedAccountType,
      subtype: subtype,
      platform: 'x',
      brandId: brandId,
      accessToken: accessToken,
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
    console.error('[X OAuth Callback Exception]', err);
    return res.status(500).send(renderHtml({
      success: false,
      title: 'Server Callback Error',
      message: err.message || 'An unexpected error occurred during X authorization.',
      actionText: 'Return to Workspace',
      actionUrl: '/accounts',
    }));
  }
};

function renderSuccessHtml({ channel, returnUrl }) {
  const safeJson = JSON.stringify(channel).replace(/</g, '\\u003c');
  const appDeepLink = `no5ocial://auth/callback?platform=x&channelId=${encodeURIComponent(channel.id)}&channelTitle=${encodeURIComponent(channel.title)}&channelHandle=${encodeURIComponent(channel.handle)}&brandId=${encodeURIComponent(channel.brandId || '')}&accountType=${encodeURIComponent(channel.accountType || 'STANDARD')}&subtype=${encodeURIComponent(channel.subtype || 'x_profile')}&accessToken=${encodeURIComponent(channel.accessToken || '')}`;
  const redirectTarget = `${returnUrl}${returnUrl.includes('?') ? '&' : '?'}connected=x&channelId=${encodeURIComponent(channel.id)}&channelTitle=${encodeURIComponent(channel.title)}&channelHandle=${encodeURIComponent(channel.handle)}&brandId=${encodeURIComponent(channel.brandId || '')}&accountType=${encodeURIComponent(channel.accountType || 'STANDARD')}&subtype=${encodeURIComponent(channel.subtype || 'x_profile')}&accessToken=${encodeURIComponent(channel.accessToken || '')}`;

  const isPremium = channel.accountType === 'PREMIUM';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>X Account Connected — no5ocial</title>
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
    .logo {
      height: 36px;
      margin-bottom: 24px;
    }
    .avatar-wrapper {
      position: relative;
      width: 80px;
      height: 80px;
      margin: 0 auto 20px;
    }
    .avatar {
      width: 80px;
      height: 80px;
      border-radius: 50%;
      object-fit: cover;
      border: 2px solid #334155;
    }
    .avatar-fallback {
      width: 80px;
      height: 80px;
      border-radius: 50%;
      background: #1E293B;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 28px;
      font-weight: 700;
      color: #94A3B8;
      border: 2px solid #334155;
    }
    .platform-icon {
      position: absolute;
      bottom: -2px;
      right: -2px;
      background: #0F1419;
      border: 2px solid #0F1420;
      width: 26px;
      height: 26px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .platform-icon svg {
      width: 14px;
      height: 14px;
      fill: #FFFFFF;
    }
    h1 {
      font-size: 22px;
      font-weight: 700;
      color: #FFFFFF;
      margin-bottom: 8px;
    }
    .handle {
      font-size: 14px;
      color: #94A3B8;
      margin-bottom: 20px;
    }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: rgba(16, 185, 129, 0.12);
      border: 1px solid rgba(16, 185, 129, 0.25);
      color: #10B981;
      font-size: 12px;
      font-weight: 600;
      padding: 6px 14px;
      border-radius: 9999px;
      margin-bottom: 28px;
    }
    .btn-primary {
      display: block;
      width: 100%;
      background: #FFFFFF;
      color: #0F1419;
      font-weight: 600;
      font-size: 15px;
      padding: 14px 20px;
      border-radius: 12px;
      text-decoration: none;
      transition: background 0.15s ease;
      cursor: pointer;
      border: none;
    }
    .btn-primary:hover {
      background: #E2E8F0;
    }
    .countdown {
      font-size: 12px;
      color: #64748B;
      margin-top: 14px;
    }
  </style>
</head>
<body>
  <div class="container">
    <img src="/assets/logo/no5ocial_white.png" alt="no5ocial" class="logo">
    <div class="avatar-wrapper">
      ${channel.avatarUrl
        ? `<img src="${channel.avatarUrl}" alt="${channel.title}" class="avatar" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">`
        : ''}
      <div class="avatar-fallback" style="${channel.avatarUrl ? 'display:none;' : ''}">
        ${(channel.title || 'X')[0].toUpperCase()}
      </div>
      <div class="platform-icon">
        <svg viewBox="0 0 24 24"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>
      </div>
    </div>
    <h1>${channel.title}</h1>
    <div class="handle">${channel.handle} &bull; ${isPremium ? 'X Premium / Verified' : 'Standard Profile'}</div>
    <div class="badge">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>
      Direct API v2 Connection Active
    </div>
    <a href="${redirectTarget}" id="actionBtn" class="btn-primary">Return to no5ocial Workspace</a>
    <div class="countdown" id="countdown">Redirecting automatically in 3 seconds...</div>
  </div>

  <script>
    (function() {
      try {
        localStorage.setItem('no5ocial_oauth_callback', JSON.stringify(${safeJson}));
      } catch (e) {
        console.warn('Could not write to localStorage:', e);
      }

      var deepLink = '${appDeepLink}';
      var webTarget = '${redirectTarget}';

      // Try deep link for mobile apps
      if (/Android|iPhone|iPad|iPod/i.test(navigator.userAgent)) {
        window.location.href = deepLink;
      }

      var seconds = 3;
      var countdownEl = document.getElementById('countdown');
      var interval = setInterval(function() {
        seconds--;
        if (seconds > 0) {
          countdownEl.textContent = 'Redirecting automatically in ' + seconds + ' second' + (seconds === 1 ? '' : 's') + '...';
        } else {
          clearInterval(interval);
          window.location.href = webTarget;
        }
      }, 1000);
    })();
  </script>
</body>
</html>`;
}

function renderHtml({ success, title, message, actionText, actionUrl }) {
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
      max-width: 520px;
      width: 100%;
      padding: 36px 32px;
      text-align: center;
    }
    .logo {
      height: 32px;
      margin-bottom: 24px;
    }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: ${success ? 'rgba(16, 185, 129, 0.15)' : 'rgba(239, 68, 68, 0.15)'};
      color: ${success ? '#10B981' : '#EF4444'};
      font-weight: 600;
      font-size: 13px;
      padding: 4px 12px;
      border-radius: 999px;
      margin-bottom: 20px;
    }
    h1 { font-size: 20px; font-weight: 700; margin: 0 0 12px; color: #FFFFFF; }
    p { font-size: 14px; line-height: 1.6; color: #94A3B8; margin: 0 0 24px; }
    .btn {
      display: inline-block;
      background: #FFFFFF;
      color: #0F1419;
      font-weight: 600;
      padding: 12px 24px;
      border-radius: 10px;
      text-decoration: none;
    }
  </style>
</head>
<body>
  <div class="card">
    <img src="/assets/logo/no5ocial_white.png" alt="no5ocial" class="logo">
    <div class="badge">${success ? 'Connected' : 'Connection Notice'}</div>
    <h1>${title}</h1>
    <p>${message}</p>
    <a href="${actionUrl}" class="btn">${actionText}</a>
  </div>
</body>
</html>`;
}
