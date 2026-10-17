const crypto = require('crypto');

module.exports = async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0');
  try {
    const brandId = req.query.brandId || '';
    const returnUrl = req.query.returnUrl || '/accounts';

    // Instagram credentials strictly loaded from environment variables
    const instagramAppId = (
      process.env.INSTAGRAM_APP_ID ||
      process.env.META_APP_ID ||
      process.env.FACEBOOK_APP_ID ||
      ''
    ).trim();

    let host = req.headers['x-forwarded-host'] || req.headers.host || 'no5ocial.vercel.app';
    if (host.includes(',')) {
      host = host.split(',')[0].trim();
    }
    const proto = req.headers['x-forwarded-proto'] || (host.includes('localhost') ? 'http' : 'https');

    // Canonical production URI strictly stripped of any trailing slash
    const redirectUri = (
      process.env.INSTAGRAM_REDIRECT_URI ||
      (host.includes('localhost')
        ? `${proto}://${host}/api/auth/callback/instagram`
        : 'https://no5ocial.vercel.app/api/auth/callback/instagram')
    ).trim().replace(/\/+$/, '');

    // Secure secret from environment
    const secret = (
      process.env.INSTAGRAM_APP_SECRET ||
      process.env.META_APP_SECRET ||
      ''
    ).trim().replace(/^["']|["']$/g, '');

    const statePayload = JSON.stringify({
      brandId,
      returnUrl,
      redirectUri,
      nonce: crypto.randomBytes(16).toString('hex'),
      timestamp: Date.now(),
    });

    const signature = crypto
      .createHmac('sha256', secret)
      .update(statePayload)
      .digest('hex');

    const state = Buffer.from(
      JSON.stringify({ payload: statePayload, sig: signature })
    ).toString('base64url');

    if (!instagramAppId || !secret) {
      const missingVars = [];
      if (!instagramAppId) missingVars.push('INSTAGRAM_APP_ID');
      if (!secret) missingVars.push('INSTAGRAM_APP_SECRET');

      if (req.query.json === 'true') {
        return res.status(500).json({
          error: `Missing required environment variables: ${missingVars.join(', ')}`,
          guidance: 'Configure INSTAGRAM_APP_ID and INSTAGRAM_APP_SECRET in your Vercel Project Settings.',
        });
      }

      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      return res.status(500).send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Instagram Configuration Required — no5ocial</title>
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
    h1 { font-size: 20px; font-weight: 700; margin: 0 0 12px; color: #FFFFFF; }
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
    <div class="badge">Configuration Missing</div>
    <h1>Missing Environment Variables</h1>
    <p>Please configure <code>${missingVars.join('</code> and <code>')}</code> in Vercel Project Settings > Environment Variables.</p>
    <a href="${returnUrl}" class="btn">Return to Workspace</a>
  </div>
</body>
</html>`);
    }

    // Official Instagram Login for Business / Creator accounts
    const scopes = [
      'instagram_business_basic',
      'instagram_business_manage_messages',
      'instagram_business_manage_comments',
      'instagram_business_content_publish',
      'instagram_business_manage_insights',
    ].join(',');

    const authUrlParams = new URLSearchParams({
      force_reauth: 'true',
      client_id: instagramAppId,
      redirect_uri: redirectUri,
      response_type: 'code',
      scope: scopes,
      state: state,
    });

    const instagramAuthUrl = `https://www.instagram.com/oauth/authorize?${authUrlParams.toString()}`;

    // Programmatic response for mobile/client app
    if (req.query.json === 'true') {
      return res.status(200).json({
        success: true,
        authUrl: instagramAuthUrl,
        redirectUri: redirectUri,
      });
    }

    // Redirect browser directly to Instagram authorization screen
    res.writeHead(302, { Location: instagramAuthUrl });
    res.end();
  } catch (err) {
    console.error('[Instagram OAuth Start Error]', err);
    res.status(500).json({
      error: 'Failed to initiate Instagram authorization',
      message: err.message,
    });
  }
};
