const handlers = {
  google: require('../_handlers/callback/google'),
  instagram: require('../_handlers/callback/instagram'),
  linkedin: require('../_handlers/callback/linkedin'),
  threads: require('../_handlers/callback/threads'),
  x: require('../_handlers/callback/x'),
  twitter: require('../_handlers/callback/x'),
};

module.exports = async function handler(req, res) {
  const platform = String(req.query.platform || '').toLowerCase().trim();
  const target = handlers[platform];

  if (!target) {
    return res.status(404).json({
      error: `Unsupported or unknown callback platform: "${platform}"`,
      supportedPlatforms: Object.keys(handlers).filter((k) => k !== 'twitter'),
    });
  }

  return target(req, res);
};
