const handlers = {
  google: require('../_handlers/start/google'),
  instagram: require('../_handlers/start/instagram'),
  linkedin: require('../_handlers/start/linkedin'),
  threads: require('../_handlers/start/threads'),
  x: require('../_handlers/start/x'),
  twitter: require('../_handlers/start/x'),
};

module.exports = async function handler(req, res) {
  const platform = String(req.query.platform || '').toLowerCase().trim();
  const target = handlers[platform];

  if (!target) {
    return res.status(404).json({
      error: `Unsupported or unknown authentication platform: "${platform}"`,
      supportedPlatforms: Object.keys(handlers).filter((k) => k !== 'twitter'),
    });
  }

  return target(req, res);
};
