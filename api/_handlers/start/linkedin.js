const crypto = require('crypto');

module.exports = async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0');
  try {
    const brandId = req.query.brandId || '';
    const returnUrl = req.query.returnUrl || '/accounts';
    // 'personal' (Member profile) or 'page' (Organization / Company Page)
    const accountType = (req.query.accountType || req.query.type || 'personal').toLowerCase();

    const clientId = (
      process.env.LINKEDIN_CLIENT_ID ||
      process.env.LINKEDIN_APP_ID ||
      ''
    ).trim();

    const clientSecret = (
      process.env.LINKEDIN_CLIENT_SECRET ||
      process.env.LINKEDIN_APP_SECRET ||
      ''
    ).trim().replace(/^["']|["']$/g, '');

    let host = req.headers['x-forwarded-host'] || req.headers.host || 'no5ocial.vercel.app';
    if (host.includes(',')) {
      host = host.split(',')[0].trim();
    }
    const proto = req.headers['x-forwarded-proto'] || (host.includes('localhost') ? 'http' : 'https');

    // Canonical redirect URI strictly matching registered redirect URL in LinkedIn Developer Portal
    const redirectUri = (
      process.env.LINKEDIN_REDIRECT_URI ||
      (host.includes('localhost')
        ? `${proto}://${host}/api/auth/callback/linkedin`
        : 'https://no5ocial.vercel.app/api/auth/callback/linkedin')
    ).trim().replace(/\/+$/, '');

    if (!clientId || !clientSecret) {
      const missingVars = [];
      if (!clientId) missingVars.push('LINKEDIN_CLIENT_ID');
      if (!clientSecret) missingVars.push('LINKEDIN_CLIENT_SECRET');

      if (req.query.json === 'true') {
        return res.status(500).json({
          error: `Missing required environment variables: ${missingVars.join(', ')}`,
          guidance: 'Configure LINKEDIN_CLIENT_ID and LINKEDIN_CLIENT_SECRET in Vercel Project Settings.',
        });
      }

      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      return res.status(500).send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>LinkedIn Configuration Required — no5ocial</title>
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
      background: #0A66C2;
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
    <div class="badge">LinkedIn API Configuration Missing</div>
    <h1>Missing Environment Variables</h1>
    <p>Please configure <code>${missingVars.join('</code> and <code>')}</code> in Vercel Project Settings > Environment Variables to enable official LinkedIn OAuth.</p>
    <a href="${returnUrl}" class="btn">Return to Workspace</a>
  </div>
</body>
</html>`);
    }

    // Scopes configuration:
    // Personal Profile: 'openid profile email w_member_social'
    // Organization / Company Page: includes organization management & social sharing
    let scopesList = ['openid', 'profile', 'email', 'w_member_social'];
    if (accountType === 'page' || accountType === 'organization') {
      scopesList = [
        'openid',
        'profile',
        'email',
        'w_member_social',
        'w_organization_social',
        'r_organization_social',
        'r_organization_admin',
        'rw_organization_admin',
      ];
    }
    const scopes = scopesList.join(' ');

    // Secure HMAC signed state parameter to protect against CSRF attacks
    const statePayload = JSON.stringify({
      brandId,
      accountType,
      returnUrl,
      redirectUri,
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
      state: state,
      scope: scopes,
    });

    const linkedinAuthUrl = `https://www.linkedin.com/oauth/v2/authorization?${authUrlParams.toString()}`;

    if (req.query.json === 'true') {
      return res.status(200).json({
        success: true,
        accountType,
        authUrl: linkedinAuthUrl,
        redirectUri,
      });
    }

    res.writeHead(302, { Location: linkedinAuthUrl });
    res.end();
  } catch (err) {
    console.error('[LinkedIn OAuth Start Error]', err);
    res.status(500).json({
      error: 'Failed to initiate LinkedIn authorization',
      message: err.message,
    });
  }
};
