const crypto = require('crypto');

module.exports = async function handler(req, res) {
  try {
    const brandId = req.query.brandId || '';
    const returnUrl = req.query.returnUrl || '/accounts';

    const clientId =
      process.env.GOOGLE_CLIENT_ID ||
      '1030532523858-o2o0l8c04r7jqdqn8d36ulkafonfafui.apps.googleusercontent.com';

    // Construct host-aware redirect URI
    let host = req.headers['x-forwarded-host'] || req.headers.host || 'no5ocial.vercel.app';
    const proto = req.headers['x-forwarded-proto'] || (host.includes('localhost') ? 'http' : 'https');
    const redirectUri =
      process.env.GOOGLE_REDIRECT_URI ||
      `${proto}://${host}/api/auth/callback/google`;

    // Create a secure signed state parameter to protect against CSRF
    const secret =
      process.env.GOOGLE_CLIENT_SECRET ||
      process.env.ENCRYPTION_SECRET ||
      'no5ocial_oauth_hmac_secret';

    const statePayload = JSON.stringify({
      brandId,
      returnUrl,
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

    const scopes = [
      'openid',
      'email',
      'profile',
      'https://www.googleapis.com/auth/youtube.upload',
      'https://www.googleapis.com/auth/youtube.readonly',
      'https://www.googleapis.com/auth/youtube.force-ssl',
    ].join(' ');

    const params = new URLSearchParams({
      client_id: clientId,
      redirect_uri: redirectUri,
      response_type: 'code',
      scope: scopes,
      access_type: 'offline',
      prompt: 'consent',
      include_granted_scopes: 'true',
      state: state,
    });

    const googleAuthUrl = `https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`;

    // If client requested JSON response (e.g. Flutter mobile or programmatic fetch)
    if (req.query.json === 'true') {
      return res.status(200).json({
        success: true,
        authUrl: googleAuthUrl,
        redirectUri: redirectUri,
      });
    }

    // Default: 302 redirect directly to Google consent screen
    res.writeHead(302, { Location: googleAuthUrl });
    res.end();
  } catch (err) {
    console.error('[Google OAuth Start Error]', err);
    res.status(500).json({
      error: 'Failed to initiate Google authorization',
      message: err.message,
    });
  }
};
