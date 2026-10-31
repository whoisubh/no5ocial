module.exports = function handler(req, res) {
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Cache-Control', 'public, max-age=86400, s-maxage=86400');

  // Baseline upload certificate fingerprint
  const fingerprints = [
    'C4:2C:FC:DA:7A:82:06:56:9B:65:F5:07:68:6A:46:53:55:24:47:AA:9C:4E:28:40:26:96:23:FB:13:57:53:E9'
  ];

  // Dynamically include Google Play App Signing Certificate SHA-256 fingerprint if configured
  if (process.env.ANDROID_PLAY_STORE_SHA256) {
    const playStoreKey = process.env.ANDROID_PLAY_STORE_SHA256.trim();
    if (playStoreKey && !fingerprints.includes(playStoreKey)) {
      fingerprints.push(playStoreKey);
    }
  }

  if (process.env.ANDROID_RELEASE_SHA256) {
    const releaseKey = process.env.ANDROID_RELEASE_SHA256.trim();
    if (releaseKey && !fingerprints.includes(releaseKey)) {
      fingerprints.push(releaseKey);
    }
  }

  res.status(200).json([
    {
      relation: [
        'delegate_permission/common.handle_all_urls',
        'delegate_permission/common.get_login_creds'
      ],
      target: {
        namespace: 'android_app',
        package_name: 'com.shaadow.no5ocial',
        sha256_cert_fingerprints: fingerprints
      }
    }
  ]);
};
