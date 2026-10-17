const crypto = require('crypto');

module.exports = async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0');
  try {
    const brandId = req.query.brandId || '';
    const returnUrl = req.query.returnUrl || '/accounts';

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

    if (!appId || !appSecret) {
      const missingVars = [];
      if (!appId) missingVars.push('THREADS_APP_ID');
      if (!appSecret) missingVars.push('THREADS_APP_SECRET');

      if (req.query.json === 'true') {
        return res.status(500).json({
          error: `Missing required environment variables: ${missingVars.join(', ')}`,
          guidance: 'Configure THREADS_APP_ID and THREADS_APP_SECRET in Vercel Project Settings.',
        });
      }

      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      return res.status(500).send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Threads Configuration Required — no5ocial</title>
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
    code { background: #1E293B; padding: 2px 6px; border-radius: 6px; color: #F1F5F9; font-size: 12px; }
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
    <div class="badge">Threads API Configuration Missing</div>
    <h1>Missing Environment Variables</h1>
    <p>Please configure <code>${missingVars.join('</code> and <code>')}</code> in Vercel Project Settings > Environment Variables to enable official Threads OAuth.</p>
    <a href="${returnUrl}" class="btn">Return to Workspace</a>
  </div>
</body>
</html>`);
    }

    // Scopes configuration for Meta Threads API:
    // threads_basic (view profile), threads_content_publish (publish threads)
    const scopes = 'threads_basic,threads_content_publish';

    // Cryptographic state parameter HMAC signed with app secret to prevent CSRF
    const statePayload = JSON.stringify({
      brandId,
      returnUrl,
      redirectUri,
      nonce: crypto.randomBytes(16).toString('hex'),
      timestamp: Date.now(),
    });

    const signature = crypto
      .createHmac('sha256', appSecret)
      .update(statePayload)
      .digest('hex');

    const state = Buffer.from(
      JSON.stringify({ payload: statePayload, sig: signature })
    ).toString('base64url');

    const authUrlParams = new URLSearchParams({
      client_id: appId,
      redirect_uri: redirectUri,
      scope: scopes,
      response_type: 'code',
      state: state,
    });

    const threadsAuthUrl = `https://threads.net/oauth/authorize?${authUrlParams.toString()}`;

    if (req.query.json === 'true') {
      return res.status(200).json({
        success: true,
        authUrl: threadsAuthUrl,
        redirectUri,
      });
    }

    res.writeHead(302, { Location: threadsAuthUrl });
    res.end();
  } catch (err) {
    console.error('[Threads OAuth Start Error]', err);
    res.status(500).json({
      error: 'Failed to initiate Threads authorization',
      message: err.message,
    });
  }
};
