const crypto = require('crypto');

module.exports = async function handler(req, res) {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');

  try {
    const { code, state, error: oauthError, error_description } = req.query;

    if (oauthError) {
      return res.status(400).send(renderHtml({
        success: false,
        title: 'Authorization Cancelled',
        message: error_description || 'You cancelled the Google Account connection or denied the requested YouTube permissions.',
        actionText: 'Return to Workspace',
        actionUrl: '/accounts',
      }));
    }

    if (!code) {
      return res.status(400).send(renderHtml({
        success: false,
        title: 'Missing Authorization Code',
        message: 'Google did not return an authorization code. Please initiate the link from no5ocial again.',
        actionText: 'Return to Workspace',
        actionUrl: '/accounts',
      }));
    }

    // Verify State & Extract Payload
    let brandId = '';
    let returnUrl = '/accounts';
    const secret = (process.env.GOOGLE_CLIENT_SECRET || process.env.ENCRYPTION_SECRET || '').trim();

    if (state && secret) {
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
        }
      } catch (e) {
        console.warn('[State Verification Warning]', e.message);
      }
    }

    const clientId = (process.env.GOOGLE_CLIENT_ID || '').trim();
    const clientSecret = (process.env.GOOGLE_CLIENT_SECRET || '').trim();

    if (!clientSecret) {
      return res.status(500).send(renderHtml({
        success: false,
        title: 'Missing Server Client Secret',
        message: 'GOOGLE_CLIENT_SECRET is not configured in Vercel Environment Variables. Please add your OAuth Client Secret to your Vercel Project Settings.',
        actionText: 'Return to Workspace',
        actionUrl: '/accounts',
      }));
    }

    let host = req.headers['x-forwarded-host'] || req.headers.host || 'no5ocial.vercel.app';
    const proto = req.headers['x-forwarded-proto'] || (host.includes('localhost') ? 'http' : 'https');
    const redirectUri =
      process.env.GOOGLE_REDIRECT_URI ||
      `${proto}://${host}/api/auth/callback/google`;

    // 1. Exchange authorization code for tokens
    const tokenParams = new URLSearchParams({
      code: code,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: redirectUri,
      grant_type: 'authorization_code',
    });

    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: tokenParams.toString(),
    });

    const tokenData = await tokenRes.json();

    if (!tokenRes.ok || tokenData.error) {
      console.error('[Token Exchange Error]', tokenData);
      return res.status(400).send(renderHtml({
        success: false,
        title: 'OAuth Token Exchange Failed',
        message: tokenData.error_description || tokenData.error || 'Failed to exchange authorization code for tokens with Google.',
        actionText: 'Try Again',
        actionUrl: '/accounts',
      }));
    }

    const accessToken = tokenData.access_token;
    const refreshToken = tokenData.refresh_token;

    // 2. Fetch YouTube Channel Information via YouTube Data API v3
    const ytRes = await fetch(
      'https://www.googleapis.com/youtube/v3/channels?part=snippet,statistics,contentDetails&mine=true',
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          Accept: 'application/json',
        },
      }
    );

    const ytData = await ytRes.json();

    if (!ytRes.ok || ytData.error) {
      console.error('[YouTube API Error]', ytData);
      return res.status(400).send(renderHtml({
        success: false,
        title: 'YouTube Data API Request Failed',
        message: ytData.error?.message || 'Unable to retrieve YouTube channels for this Google Account.',
        actionText: 'Return to Workspace',
        actionUrl: '/accounts',
      }));
    }

    if (!ytData.items || ytData.items.length === 0) {
      return res.status(200).send(renderHtml({
        success: false,
        title: 'No YouTube Channel Found',
        message: 'This Google account does not currently have an active YouTube channel. Please visit <a href="https://youtube.com/create_channel" target="_blank" style="color: #38BDF8;">youtube.com/create_channel</a> to set up your channel, then try connecting again.',
        actionText: 'Return to Accounts',
        actionUrl: '/accounts',
      }));
    }

    // Extract primary channel details
    const channel = ytData.items[0];
    const channelId = channel.id;
    const channelTitle = channel.snippet.title || 'YouTube Channel';
    const customUrl = channel.snippet.customUrl || '';
    const channelHandle = customUrl
      ? (customUrl.startsWith('@') ? customUrl : `@${customUrl}`)
      : `@${channelTitle.replace(/\s+/g, '').toLowerCase()}`;

    const avatarUrl =
      channel.snippet.thumbnails?.medium?.url ||
      channel.snippet.thumbnails?.default?.url ||
      '';

    const subscriberCount = channel.statistics?.subscriberCount || '0';
    const videoCount = channel.statistics?.videoCount || '0';

    const channelPayload = {
      id: channelId,
      title: channelTitle,
      handle: channelHandle,
      avatarUrl: avatarUrl,
      subscriberCount: parseInt(subscriberCount, 10),
      videoCount: parseInt(videoCount, 10),
      platform: 'youtube',
      brandId: brandId,
      hasRefreshToken: !!refreshToken,
    };

    // Return HTML that posts message to opener window and updates client state
    return res.status(200).send(renderSuccessHtml({
      channel: channelPayload,
      returnUrl: returnUrl,
    }));
  } catch (err) {
    console.error('[OAuth Callback Exception]', err);
    return res.status(500).send(renderHtml({
      success: false,
      title: 'Server Callback Error',
      message: err.message || 'An unexpected error occurred during Google authorization.',
      actionText: 'Return to Workspace',
      actionUrl: '/accounts',
    }));
  }
};

function renderSuccessHtml({ channel, returnUrl }) {
  const safeJson = JSON.stringify(channel).replace(/</g, '\\u003c');
  const appDeepLink = `no5ocial://auth/callback?channelId=${encodeURIComponent(channel.id)}&channelTitle=${encodeURIComponent(channel.title)}&channelHandle=${encodeURIComponent(channel.handle)}&brandId=${encodeURIComponent(channel.brandId || '')}`;
  const redirectTarget = `${returnUrl}${returnUrl.includes('?') ? '&' : '?'}connected=youtube&channelId=${encodeURIComponent(channel.id)}&channelTitle=${encodeURIComponent(channel.title)}&channelHandle=${encodeURIComponent(channel.handle)}`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>YouTube Channel Connected — no5ocial</title>
  <link rel="icon" type="image/png" href="/favicon.png">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    body {
      background: #07090E;
      color: #F1F5F9;
      font-family: 'Inter', sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      padding: 20px;
      box-sizing: border-box;
    }
    .card {
      background: #0F1420;
      border: 1px solid #1E293B;
      border-radius: 16px;
      padding: 36px 32px;
      max-width: 480px;
      width: 100%;
      text-align: center;
      box-shadow: 0 10px 30px rgba(0,0,0,0.5);
    }
    .logo {
      height: 32px;
      margin-bottom: 24px;
    }
    .badge-icon {
      width: 64px;
      height: 64px;
      border-radius: 50%;
      background: rgba(16, 185, 129, 0.12);
      border: 1px solid rgba(16, 185, 129, 0.3);
      color: #10B981;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 16px;
      font-size: 32px;
    }
    h1 {
      font-size: 1.5rem;
      font-weight: 700;
      margin-bottom: 8px;
    }
    .channel-box {
      background: #172033;
      border: 1px solid #2A374E;
      border-radius: 12px;
      padding: 16px;
      margin: 20px 0;
      display: flex;
      align-items: center;
      gap: 14px;
      text-align: left;
    }
    .channel-avatar {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      object-fit: cover;
      background: #2A374E;
    }
    .channel-title {
      font-weight: 700;
      font-size: 1.05rem;
      color: #FFF;
    }
    .channel-handle {
      font-size: 0.85rem;
      color: #94A3B8;
    }
    .channel-meta {
      font-size: 0.75rem;
      color: #38BDF8;
      margin-top: 2px;
    }
    .btn {
      display: inline-block;
      width: 100%;
      box-sizing: border-box;
      background: linear-gradient(135deg, #10B981, #059669);
      color: #FFF;
      text-decoration: none;
      padding: 12px 20px;
      border-radius: 10px;
      font-weight: 600;
      font-size: 0.95rem;
      transition: opacity 0.2s;
    }
    .btn:hover { opacity: 0.9; }
    .btn-secondary {
      background: #172033;
      border: 1px solid #2A374E;
      color: #94A3B8;
    }
    .btn-secondary:hover {
      background: #1E293B;
      color: #FFF;
    }
    .status-text {
      font-size: 0.8rem;
      color: #64748B;
      margin-top: 14px;
    }
    .copy-box {
      margin-top: 16px;
      padding: 12px;
      background: #0B0F19;
      border: 1px dashed #2A374E;
      border-radius: 8px;
      font-size: 0.8rem;
      color: #94A3B8;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
    }
    .copy-btn {
      background: transparent;
      border: 1px solid #38BDF8;
      color: #38BDF8;
      border-radius: 6px;
      padding: 4px 10px;
      cursor: pointer;
      font-size: 0.75rem;
      white-space: nowrap;
    }
  </style>
</head>
<body>
  <div class="card">
    <img src="/assets/logo/no5ocial_white.png" alt="no5ocial" class="logo">
    <div class="badge-icon">&#10003;</div>
    <h1>YouTube Channel Linked</h1>
    <p style="color: #94A3B8; font-size: 0.9rem;">Your official YouTube channel has been verified via the YouTube Data API v3.</p>

    <div class="channel-box">
      ${channel.avatarUrl ? `<img src="${channel.avatarUrl}" class="channel-avatar" alt="${channel.title}">` : '<div class="channel-avatar"></div>'}
      <div>
        <div class="channel-title">${channel.title}</div>
        <div class="channel-handle">${channel.handle}</div>
        <div class="channel-meta">${channel.subscriberCount.toLocaleString()} subscribers &bull; ${channel.videoCount} videos</div>
      </div>
    </div>

    <div style="display: flex; flex-direction: column; gap: 10px;">
      <a href="${appDeepLink}" class="btn" id="appReturnBtn">Return to no5ocial App</a>
      <a href="${redirectTarget}" class="btn btn-secondary" id="returnBtn">Open Web Workspace</a>
    </div>

    <div class="copy-box">
      <div style="text-align: left; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
        <span>Channel ID: </span><code style="color: #38BDF8; user-select: all;">${channel.id}</code>
      </div>
      <button class="copy-btn" id="copyBtn" onclick="navigator.clipboard.writeText('${channel.id}'); this.innerText='Copied!';">Copy ID</button>
    </div>

    <div class="status-text" id="statusText">Credentials verified. Tap above to return to your workspace.</div>
  </div>

  <script>
    const channelData = ${safeJson};
    try {
      // 1. Post message to opener window if opened in popup
      if (window.opener && !window.opener.closed) {
        window.opener.postMessage({
          type: 'NO5OCIAL_YOUTUBE_CONNECTED',
          channel: channelData
        }, '*');
      }

      // 2. Persist in localStorage so any open or newly opened no5ocial tab picks it up
      localStorage.setItem('no5ocial_connected_account', JSON.stringify({
        timestamp: Date.now(),
        channel: channelData
      }));
    } catch (e) {
      console.warn('Storage sync error:', e);
    }

    // On mobile devices, attempt automatic deep link back to app after brief confirmation
    const isMobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
    setTimeout(function() {
      if (window.opener && !window.opener.closed) {
        window.close();
      } else if (isMobile) {
        // Try switching back to native app
        window.location.href = "${appDeepLink}";
      }
    }, 1500);
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
      background: #07090E;
      color: #F1F5F9;
      font-family: 'Inter', sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      padding: 20px;
      box-sizing: border-box;
    }
    .card {
      background: #0F1420;
      border: 1px solid #1E293B;
      border-radius: 16px;
      padding: 36px 32px;
      max-width: 480px;
      width: 100%;
      text-align: center;
      box-shadow: 0 10px 30px rgba(0,0,0,0.5);
    }
    .logo {
      height: 32px;
      margin-bottom: 24px;
    }
    .badge-icon {
      width: 60px;
      height: 60px;
      border-radius: 50%;
      background: ${success ? 'rgba(16, 185, 129, 0.12)' : 'rgba(239, 68, 68, 0.12)'};
      border: 1px solid ${success ? 'rgba(16, 185, 129, 0.3)' : 'rgba(239, 68, 68, 0.3)'};
      color: ${success ? '#10B981' : '#EF4444'};
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 16px;
      font-size: 28px;
    }
    h1 {
      font-size: 1.4rem;
      font-weight: 700;
      margin-bottom: 12px;
    }
    p {
      color: #94A3B8;
      font-size: 0.95rem;
      line-height: 1.6;
      margin-bottom: 24px;
    }
    .btn {
      display: inline-block;
      background: linear-gradient(135deg, #38BDF8, #6366F1);
      color: #FFF;
      text-decoration: none;
      padding: 12px 24px;
      border-radius: 10px;
      font-weight: 600;
      font-size: 0.95rem;
    }
  </style>
</head>
<body>
  <div class="card">
    <img src="/assets/logo/no5ocial_white.png" alt="no5ocial" class="logo">
    <div class="badge-icon">${success ? '&#10003;' : '&#9888;'}</div>
    <h1>${title}</h1>
    <p>${message}</p>
    <a href="${actionUrl}" class="btn">${actionText}</a>
  </div>
</body>
</html>`;
}
