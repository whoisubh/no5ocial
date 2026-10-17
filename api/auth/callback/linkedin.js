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
        title: 'LinkedIn Authorization Cancelled',
        message: error_description || 'You cancelled the LinkedIn account authorization or denied requested publishing permissions.',
        actionText: 'Return to Workspace',
        actionUrl: '/accounts',
      }));
    }

    if (!code) {
      return res.status(400).send(renderHtml({
        success: false,
        title: 'Missing Authorization Code',
        message: 'LinkedIn did not return an authorization code. Please initiate the link from no5ocial again.',
        actionText: 'Return to Workspace',
        actionUrl: '/accounts',
      }));
    }

    // Clean authorization code
    const cleanCode = code ? String(code).replace(/#_$/, '').split('#')[0].trim() : '';

    if (successfulExchanges.has(cleanCode)) {
      const cached = successfulExchanges.get(cleanCode);
      return res.status(200).send(renderSuccessHtml(cached));
    }

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

    if (!clientId || !clientSecret) {
      return res.status(500).send(renderHtml({
        success: false,
        title: 'Server Configuration Error',
        message: 'LINKEDIN_CLIENT_ID and/or LINKEDIN_CLIENT_SECRET are not configured in Vercel environment variables.',
        actionText: 'Return to Workspace',
        actionUrl: '/accounts',
      }));
    }

    let brandId = '';
    let accountType = 'personal';
    let returnUrl = '/accounts';
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
          accountType = (payload.accountType || 'personal').toLowerCase();
          returnUrl = payload.returnUrl || '/accounts';
          if (payload.redirectUri) {
            stateRedirectUri = payload.redirectUri;
          }
        }
      } catch (e) {
        console.warn('[LinkedIn State Verification Warning]', e.message);
      }
    }

    let host = req.headers['x-forwarded-host'] || req.headers.host || 'no5ocial.vercel.app';
    if (host.includes(',')) {
      host = host.split(',')[0].trim();
    }
    const proto = req.headers['x-forwarded-proto'] || (host.includes('localhost') ? 'http' : 'https');

    let redirectUri = (
      stateRedirectUri ||
      process.env.LINKEDIN_REDIRECT_URI ||
      (host.includes('localhost')
        ? `${proto}://${host}/api/auth/callback/linkedin`
        : 'https://no5ocial.vercel.app/api/auth/callback/linkedin')
    ).trim().replace(/\/+$/, '');

    // 1. Exchange authorization code for LinkedIn access token
    const tokenFormData = new URLSearchParams({
      grant_type: 'authorization_code',
      code: cleanCode,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: redirectUri,
    });

    const tokenRes = await fetch('https://www.linkedin.com/oauth/v2/accessToken', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: tokenFormData.toString(),
    });

    const tokenData = await tokenRes.json();

    if (!tokenRes.ok || !tokenData.access_token) {
      console.error('[LinkedIn Token Exchange Error]', tokenData);
      return res.status(400).send(renderHtml({
        success: false,
        title: 'LinkedIn Token Exchange Failed',
        message: tokenData.error_description || tokenData.error || 'LinkedIn rejected the authorization exchange.',
        actionText: 'Authorize LinkedIn Again',
        actionUrl: `/api/auth/linkedin/start?brandId=${encodeURIComponent(brandId)}&accountType=${encodeURIComponent(accountType)}&returnUrl=/accounts`,
        debugDetails: JSON.stringify({
          api_response: tokenData,
          redirect_uri_used: redirectUri,
          client_id: clientId,
        }, null, 2),
      }));
    }

    const accessToken = tokenData.access_token;

    // 2. Fetch authenticated Member Profile via OpenID Connect endpoint (/v2/userinfo)
    const userinfoRes = await fetch('https://api.linkedin.com/v2/userinfo', {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        Accept: 'application/json',
      },
    });

    const userinfo = userinfoRes.ok ? await userinfoRes.json() : {};
    const memberSub = userinfo.sub || '';
    const memberName = userinfo.name || `${userinfo.given_name || ''} ${userinfo.family_name || ''}`.trim() || 'LinkedIn Member';
    const memberPicture = userinfo.picture || '';
    const memberHandle = userinfo.email ? `@${userinfo.email.split('@')[0]}` : `@${memberName.toLowerCase().replace(/\s+/g, '')}`;

    let channelId = `urn:li:person:${memberSub}`;
    let channelTitle = memberName;
    let channelHandle = memberHandle;
    let channelAvatar = memberPicture;
    let resolvedAccountType = 'PERSONAL';
    let availablePages = [];

    // 3. If connecting a Company Page, query user's administered organizations
    if (accountType === 'page' || accountType === 'organization') {
      try {
        // Query /rest/organizationAcls with versioning headers
        let aclsRes = await fetch('https://api.linkedin.com/rest/organizationAcls?q=roleAssignee', {
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'X-Restli-Protocol-Version': '2.0.0',
            'LinkedIn-Version': '202401',
            Accept: 'application/json',
          },
        });

        // Fallback to /v2/organizationalEntityAcls if needed
        if (!aclsRes.ok) {
          aclsRes = await fetch('https://api.linkedin.com/v2/organizationalEntityAcls?q=roleAssignee&state=APPROVED', {
            headers: {
              Authorization: `Bearer ${accessToken}`,
              'X-Restli-Protocol-Version': '2.0.0',
              Accept: 'application/json',
            },
          });
        }

        if (aclsRes.ok) {
          const aclsData = await aclsRes.json();
          const elements = aclsData.elements || [];

          for (const item of elements) {
            const orgUrn = item.organization || item.organizationalTarget;
            const role = item.role;
            if (orgUrn && (role === 'ADMINISTRATOR' || role === 'CONTENT_ADMINISTRATOR' || role === 'DIRECT_SPONSORED_CONTENT_POSTER' || !role)) {
              const numericId = orgUrn.split(':').pop();
              availablePages.push({
                urn: orgUrn.startsWith('urn:li:organization:') ? orgUrn : `urn:li:organization:${numericId}`,
                id: numericId,
                role: role || 'ADMINISTRATOR',
              });
            }
          }
        }

        // Fetch organization details for the primary administered page
        if (availablePages.length > 0) {
          const primaryOrg = availablePages[0];
          try {
            const orgRes = await fetch(`https://api.linkedin.com/rest/organizations/${primaryOrg.id}`, {
              headers: {
                Authorization: `Bearer ${accessToken}`,
                'X-Restli-Protocol-Version': '2.0.0',
                'LinkedIn-Version': '202401',
                Accept: 'application/json',
              },
            });

            if (orgRes.ok) {
              const orgData = await orgRes.json();
              channelId = primaryOrg.urn;
              channelTitle = orgData.localizedName || orgData.name || `LinkedIn Page (${primaryOrg.id})`;
              channelHandle = orgData.vanityName ? `@${orgData.vanityName}` : `@org_${primaryOrg.id}`;
              resolvedAccountType = 'PAGE';
            } else {
              channelId = primaryOrg.urn;
              channelTitle = `LinkedIn Organization (${primaryOrg.id})`;
              channelHandle = `@org_${primaryOrg.id}`;
              resolvedAccountType = 'PAGE';
            }
          } catch (orgErr) {
            channelId = primaryOrg.urn;
            channelTitle = `LinkedIn Organization (${primaryOrg.id})`;
            channelHandle = `@org_${primaryOrg.id}`;
            resolvedAccountType = 'PAGE';
          }
        } else {
          // User requested Page but does not have Company Page Admin access
          console.warn('[LinkedIn Page Admin Not Found] User has no administered organizations, falling back to member profile with notification');
        }
      } catch (pageErr) {
        console.warn('[LinkedIn Organizations Fetch Warning]', pageErr.message);
      }
    }

    const channelPayload = {
      id: channelId,
      title: channelTitle,
      handle: channelHandle,
      avatarUrl: channelAvatar,
      accountType: resolvedAccountType,
      platform: 'linkedin',
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
    console.error('[LinkedIn OAuth Callback Exception]', err);
    return res.status(500).send(renderHtml({
      success: false,
      title: 'Server Callback Error',
      message: err.message || 'An unexpected error occurred during LinkedIn authorization.',
      actionText: 'Return to Workspace',
      actionUrl: '/accounts',
    }));
  }
};

function renderSuccessHtml({ channel, returnUrl }) {
  const safeJson = JSON.stringify(channel).replace(/</g, '\\u003c');
  const appDeepLink = `no5ocial://auth/callback?platform=linkedin&channelId=${encodeURIComponent(channel.id)}&channelTitle=${encodeURIComponent(channel.title)}&channelHandle=${encodeURIComponent(channel.handle)}&brandId=${encodeURIComponent(channel.brandId || '')}&accountType=${encodeURIComponent(channel.accountType || 'PERSONAL')}&accessToken=${encodeURIComponent(channel.accessToken || '')}`;
  const redirectTarget = `${returnUrl}${returnUrl.includes('?') ? '&' : '?'}connected=linkedin&channelId=${encodeURIComponent(channel.id)}&channelTitle=${encodeURIComponent(channel.title)}&channelHandle=${encodeURIComponent(channel.handle)}`;

  const isPage = channel.accountType === 'PAGE';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>LinkedIn ${isPage ? 'Page' : 'Profile'} Connected — no5ocial</title>
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
      background: #0A66C2;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 20px;
      box-shadow: 0 10px 25px rgba(10, 102, 194, 0.35);
    }
    .icon-badge svg {
      width: 32px;
      height: 32px;
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
      border-radius: ${isPage ? '10px' : '50%'};
      background: #334155;
      margin-right: 14px;
      object-fit: cover;
    }
    .avatar-fallback {
      width: 48px;
      height: 48px;
      border-radius: ${isPage ? '10px' : '50%'};
      background: #0A66C2;
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
      color: #38BDF8;
      font-weight: 500;
    }
    .btn-primary {
      display: block;
      width: 100%;
      background: #0A66C2;
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
      <svg viewBox="0 0 24 24"><path d="M19 3a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h14m-.5 15.5v-5.3a3.26 3.26 0 0 0-3.26-3.26c-.85 0-1.84.52-2.28 1.3v-1.11h-2.79v8.37h2.79v-4.93c0-.77.62-1.4 1.39-1.4a1.4 1.4 0 0 1 1.4 1.4v4.93h2.75M6.46 10.9v8.37H9.25V10.9H6.46M7.86 6.81a1.45 1.45 0 1 0 0 2.9 1.45 1.45 0 0 0 0-2.9z"/></svg>
    </div>
    <h1>LinkedIn ${isPage ? 'Company Page' : 'Profile'} Connected!</h1>
    <p class="subtitle">Your LinkedIn ${isPage ? 'organization' : 'member account'} is successfully linked and verified via official LinkedIn API.</p>

    <div class="channel-card">
      ${channel.avatarUrl ? `<img src="${channel.avatarUrl}" class="avatar" alt="Avatar">` : `<div class="avatar-fallback">${channel.title.charAt(0)}</div>`}
      <div class="channel-info">
        <h3>${channel.title}</h3>
        <p>${channel.handle} • ${channel.accountType === 'PAGE' ? 'Company Page (urn:li:organization)' : 'Personal Profile (urn:li:person)'}</p>
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
    <div class="badge">${success ? 'Success' : 'Authorization Notice'}</div>
    <h1>${title}</h1>
    <p>${message}</p>
    <a href="${actionUrl}" class="btn">${actionText}</a>
    <a href="no5ocial://auth/callback?error=cancelled" style="display:block; margin-top:16px; color:#94A3B8; text-decoration:underline; font-size:13px;">Return to no5ocial App</a>
    ${debugDetails ? `
    <details style="margin-top:20px; text-align:left; background:#07090E; border:1px solid #1F2937; border-radius:8px; padding:12px; font-size:12px; color:#94A3B8; max-height:220px; overflow-y:auto;">
      <summary style="cursor:pointer; color:#0A66C2; font-weight:600;">Technical Diagnostics</summary>
      <pre style="white-space:pre-wrap; word-break:break-all; margin-top:8px; font-size:11px;">${debugDetails.replace(/</g, '&lt;')}</pre>
    </details>` : ''}
  </div>
</body>
</html>`;
}
