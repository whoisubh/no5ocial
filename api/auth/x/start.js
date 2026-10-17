const crypto = require('crypto');

module.exports = async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0');
  try {
    const brandId = req.query.brandId || '';
    const returnUrl = req.query.returnUrl || '/accounts';
    // 'standard' (Standard profile) or 'premium' (X Premium / Verified Organization)
    const accountType = (req.query.accountType || req.query.type || 'standard').toLowerCase();

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

    let host = req.headers['x-forwarded-host'] || req.headers.host || 'no5ocial.vercel.app';
    if (host.includes(',')) {
      host = host.split(',')[0].trim();
    }
    const proto = req.headers['x-forwarded-proto'] || (host.includes('localhost') ? 'http' : 'https');

    // Canonical redirect URI strictly matching registered redirect URL in X Developer Portal
    const redirectUri = (
      process.env.X_REDIRECT_URI ||
      process.env.TWITTER_REDIRECT_URI ||
      (host.includes('localhost')
        ? `${proto}://${host}/api/auth/callback/x`
        : 'https://no5ocial.vercel.app/api/auth/callback/x')
    ).trim().replace(/\/+$/, '');

    if (!clientId || !clientSecret) {
      const missingVars = [];
      if (!clientId) missingVars.push('X_CLIENT_ID (or TWITTER_CLIENT_ID)');
      if (!clientSecret) missingVars.push('X_CLIENT_SECRET (or TWITTER_CLIENT_SECRET)');

      if (req.query.json === 'true') {
        return res.status(500).json({
          error: `Missing required environment variables: ${missingVars.join(', ')}`,
          guidance: 'Configure X_CLIENT_ID and X_CLIENT_SECRET in Vercel Project Settings.',
        });
      }

      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      return res.status(500).send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>X (Twitter) Configuration Required — no5ocial</title>
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
      background: #0F1419;
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
    <div class="badge">X (Twitter) API Configuration Missing</div>
    <h1>Missing Environment Variables</h1>
    <p>Please configure <code>${missingVars.join('</code> and <code>')}</code> in Vercel Project Settings > Environment Variables to enable official X OAuth 2.0 PKCE.</p>
    <a href="${returnUrl}" class="btn">Return to Workspace</a>
  </div>
</body>
</html>`);
    }

    // Scopes configuration for X API v2:
    // tweet.read, tweet.write, users.read, offline.access
    const scopes = 'tweet.read tweet.write users.read offline.access';

    // Generate cryptographic PKCE code_verifier (43-128 characters) and SHA-256 code_challenge
    const codeVerifier = crypto.randomBytes(32).toString('base64url');
    const codeChallenge = crypto.createHash('sha256').update(codeVerifier).digest('base64url');

    // Secure HMAC signed state parameter to protect against CSRF attacks and transport PKCE verifier safely
    const statePayload = JSON.stringify({
      brandId,
      accountType,
      returnUrl,
      redirectUri,
      codeVerifier,
      nonce: crypto.randomBytes(16).toString('hex'),
      timestamp: Date.now(),
    });

    const signature = crypto
      .createHmac('sha256', clientSecret)
      .update(statePayload)
      .digest('hex');

    const state = Buffer.from(
      JSON.stringify({ payload: statePayload, sig: signature })
    ).toString('base64url');

    const authUrlParams = new URLSearchParams({
      response_type: 'code',
      client_id: clientId,
      redirect_uri: redirectUri,
      scope: scopes,
      state: state,
      code_challenge: codeChallenge,
      code_challenge_method: 'S256',
    });

    const xAuthUrl = `https://x.com/i/oauth2/authorize?${authUrlParams.toString()}`;

    if (req.query.json === 'true') {
      return res.status(200).json({
        success: true,
        accountType,
        authUrl: xAuthUrl,
        redirectUri,
      });
    }

    res.writeHead(302, { Location: xAuthUrl });
    res.end();
  } catch (err) {
    console.error('[X OAuth Start Error]', err);
    res.status(500).json({
      error: 'Failed to initiate X authorization',
      message: err.message,
    });
  }
};
