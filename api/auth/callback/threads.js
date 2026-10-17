const crypto = require('crypto');

// In-memory cache to prevent double execution / prefetch code burning on Vercel
const successfulExchanges = new Map();

module.exports = async function handler(req, res) {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0');
  res.setHeader('Pragma', 'no-cache');

  if (req.method === 'HEAD') return res.status(200).end();
  if (req.headers['purpose'] === 'prefetch' || req.headers['sec-purpose'] === 'prefetch') {
    return res.status(204).end();
  }

  try {
    const { code, state, error: oauthError, error_description } = req.query;

    if (oauthError) {
      return res.status(400).send(renderHtml({
        success: false,
        title: 'Threads Authorization Cancelled',
        message: error_description || 'You cancelled the Threads authorization or denied requested publishing permissions.',
        actionText: 'Return to Workspace',
        actionUrl: '/accounts',
      }));
    }

    if (!code) {
      return res.status(400).send(renderHtml({
        success: false,
        title: 'Missing Authorization Code',
        message: 'Threads did not return an authorization code. Please initiate the link from no5ocial again.',
        actionText: 'Return to Workspace',
        actionUrl: '/accounts',
      }));
    }

    const cleanCode = code ? String(code).replace(/#_$/, '').split('#')[0].trim() : '';

    if (successfulExchanges.has(cleanCode)) {
      const cached = successfulExchanges.get(cleanCode);
      return res.status(200).send(renderSuccessHtml(cached));
    }

    const appId = (
      process.env.THREADS_APP_ID ||
      process.env.THREADS_CLIENT_ID ||
      process.env.META_APP_ID ||
      ''
    ).trim();

    const appSecret = (
      process.env.THREADS_APP_SECRET ||
      process.env.THREADS_CLIENT_SECRET ||
      process.env.META_APP_SECRET ||
      ''
    ).trim().replace(/^["']|["']$/g, '');

    if (!appId || !appSecret) {
      return res.status(500).send(renderHtml({
        success: false,
        title: 'Configuration Error',
        message: 'THREADS_APP_ID and/or THREADS_APP_SECRET are not configured in Vercel environment variables.',
        actionText: 'Return to Workspace',
        actionUrl: '/accounts',
      }));
    }

    let brandId = '';
    let returnUrl = '/accounts';

    if (state) {
      try {
        const stateRaw = Buffer.from(state, 'base64url').toString('utf8');
        const stateObj = JSON.parse(stateRaw);
        const { payload, sig } = stateObj;

        const expectedSig = crypto
          .createHmac('sha256', appSecret)
          .update(payload)
          .digest('hex');

        if (sig === expectedSig) {
          const parsedPayload = JSON.parse(payload);
          brandId = parsedPayload.brandId || '';
          returnUrl = parsedPayload.returnUrl || '/accounts';
        } else {
          console.warn('[Threads State Signature Mismatch] Possible CSRF attempt.');
        }
      } catch (e) {
        console.warn('[Threads State Verification Warning]', e.message);
      }
    }

    let host = req.headers['x-forwarded-host'] || req.headers.host || 'no5ocial.vercel.app';
    if (host.includes(',')) {
      host = host.split(',')[0].trim();
    }
    const proto = req.headers['x-forwarded-proto'] || (host.includes('localhost') ? 'http' : 'https');

    const redirectUri = (
      process.env.THREADS_REDIRECT_URI ||
      (host.includes('localhost')
        ? `${proto}://${host}/api/auth/callback/threads`
        : 'https://no5ocial.vercel.app/api/auth/callback/threads')
    ).trim().replace(/\/+$/, '');

    // 1. Exchange authorization code for short-lived access token
    const tokenParams = new URLSearchParams({
      client_id: appId,
      client_secret: appSecret,
      grant_type: 'authorization_code',
      redirect_uri: redirectUri,
      code: cleanCode,
    });

    const tokenResponse = await fetch('https://graph.threads.net/oauth/access_token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: tokenParams.toString(),
    });

    const tokenData = await tokenResponse.json();

    if (!tokenResponse.ok || !tokenData.access_token) {
      console.error('[Threads Token Exchange Error]', tokenData);
      return res.status(400).send(renderHtml({
        success: false,
        title: 'Token Exchange Failed',
        message: tokenData.error_message || tokenData.error?.message || 'Failed to exchange authorization code for Threads access token.',
        actionText: 'Try Again',
        actionUrl: `/api/auth/threads/start?brandId=${encodeURIComponent(brandId)}`,
      }));
    }

    let finalAccessToken = tokenData.access_token;
    const userId = tokenData.user_id ? String(tokenData.user_id) : '';

    // 2. Exchange short-lived token for long-lived 60-day token
    try {
      const longLivedUrl = `https://graph.threads.net/access_token?grant_type=th_exchange_token&client_secret=${encodeURIComponent(appSecret)}&access_token=${encodeURIComponent(finalAccessToken)}`;
      const longLivedRes = await fetch(longLivedUrl);
      if (longLivedRes.ok) {
        const longLivedData = await longLivedRes.json();
        if (longLivedData.access_token) {
          finalAccessToken = longLivedData.access_token;
        }
      }
    } catch (exchangeErr) {
      console.warn('[Threads Long-Lived Token Exchange Warning]', exchangeErr.message);
    }

    // 3. Fetch authenticated user profile: GET https://graph.threads.net/v1.0/me
    const userProfileUrl = `https://graph.threads.net/v1.0/me?fields=id,username,name,threads_profile_picture_url&access_token=${encodeURIComponent(finalAccessToken)}`;
    const userResponse = await fetch(userProfileUrl);

    let username = 'threads_user';
    let displayName = 'Threads Account';
    let profileId = userId || 'threads_me';
    let avatarUrl = '';

    if (userResponse.ok) {
      const userData = await userResponse.json();
      profileId = userData.id || profileId;
      username = userData.username || username;
      displayName = userData.name || userData.username || displayName;
      avatarUrl = userData.threads_profile_picture_url || '';
    }

    const channel = {
      id: profileId,
      title: displayName,
      handle: username.startsWith('@') ? username : `@${username}`,
      brandId,
      subtype: 'threads_profile',
      platform: 'threads',
      avatarUrl,
      accessToken: finalAccessToken,
    };

    successfulExchanges.set(cleanCode, { channel, returnUrl });
    if (successfulExchanges.size > 200) {
      const oldestKey = successfulExchanges.keys().next().value;
      successfulExchanges.delete(oldestKey);
    }

    return res.status(200).send(renderSuccessHtml({ channel, returnUrl }));
  } catch (err) {
    console.error('[Threads OAuth Callback Exception]', err);
    return res.status(500).send(renderHtml({
      success: false,
      title: 'Authentication Error',
      message: err.message || 'An unexpected error occurred during Threads authorization.',
      actionText: 'Return to Workspace',
      actionUrl: '/accounts',
    }));
  }
};

function renderSuccessHtml({ channel, returnUrl }) {
  const appDeepLink = `no5ocial://auth/callback?platform=threads&channelId=${encodeURIComponent(channel.id)}&channelTitle=${encodeURIComponent(channel.title)}&channelHandle=${encodeURIComponent(channel.handle)}&brandId=${encodeURIComponent(channel.brandId || '')}&accountType=PROFILE&subtype=threads_profile&accessToken=${encodeURIComponent(channel.accessToken || '')}`;
  const redirectTarget = `${returnUrl}${returnUrl.includes('?') ? '&' : '?'}connected=threads&channelId=${encodeURIComponent(channel.id)}&channelTitle=${encodeURIComponent(channel.title)}&channelHandle=${encodeURIComponent(channel.handle)}&brandId=${encodeURIComponent(channel.brandId || '')}&accountType=PROFILE&subtype=threads_profile&accessToken=${encodeURIComponent(channel.accessToken || '')}`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Threads Account Connected — no5ocial</title>
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
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
    }
    .logo {
      height: 32px;
      margin-bottom: 24px;
    }
    .icon-wrap {
      width: 56px;
      height: 56px;
      border-radius: 50%;
      background: rgba(16, 185, 129, 0.15);
      color: #10B981;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 18px;
    }
    .icon-wrap svg {
      width: 28px;
      height: 28px;
    }
    h1 {
      font-size: 20px;
      font-weight: 700;
      margin: 0 0 8px;
      color: #FFFFFF;
    }
    .channel-name {
      font-size: 16px;
      font-weight: 600;
      color: #F8FAFC;
      margin-bottom: 4px;
    }
    .handle {
      font-size: 13px;
      color: #94A3B8;
      margin-bottom: 24px;
    }
    .btn {
      display: inline-block;
      background: #101010;
      border: 1px solid #334155;
      color: #FFFFFF;
      font-weight: 600;
      padding: 12px 24px;
      border-radius: 10px;
      text-decoration: none;
      transition: all 0.15s ease;
    }
    .btn:hover {
      background: #202020;
    }
  </style>
  <script>
    setTimeout(function() {
      try {
        window.location.href = ${JSON.stringify(appDeepLink)};
      } catch (e) {}
      setTimeout(function() {
        window.location.href = ${JSON.stringify(redirectTarget)};
      }, 800);
    }, 400);
  </script>
</head>
<body>
  <div class="card">
    <img src="/assets/logo/no5ocial_white.png" alt="no5ocial" class="logo">
    <div class="icon-wrap">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="20 6 9 17 4 12"></polyline>
      </svg>
    </div>
    <h1>Account Connected!</h1>
    <div class="channel-name">${channel.title}</div>
    <div class="handle">${channel.handle} &bull; Threads Profile</div>
    <a href="${redirectTarget}" class="btn">Return to no5ocial</a>
  </div>
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
      max-width: 480px;
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
      background: rgba(239, 68, 68, 0.15);
      color: #EF4444;
      font-weight: 600;
      font-size: 13px;
      padding: 4px 12px;
      border-radius: 999px;
      margin-bottom: 20px;
    }
    h1 {
      font-size: 20px;
      font-weight: 700;
      margin: 0 0 12px;
      color: #FFFFFF;
    }
    p {
      font-size: 14px;
      line-height: 1.6;
      color: #94A3B8;
      margin: 0 0 24px;
    }
    .btn {
      display: inline-block;
      background: #101010;
      border: 1px solid #334155;
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
    <img src="/assets/logo/no5ocial_white.png" alt="no5ocial" class="logo">
    <div class="badge">Authentication Notice</div>
    <h1>${title}</h1>
    <p>${message}</p>
    <a href="${actionUrl}" class="btn">${actionText}</a>
  </div>
</body>
</html>`;
}
