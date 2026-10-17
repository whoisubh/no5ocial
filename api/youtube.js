const handlers = {
  channels: require('./_handlers/youtube/channels'),
  status: require('./_handlers/youtube/status'),
  upload: require('./_handlers/youtube/upload'),
};

module.exports = async function handler(req, res) {
  const action = String(req.query.action || '').toLowerCase().trim();
  const target = handlers[action];

  if (!target) {
    return res.status(404).json({
      error: `Unsupported YouTube action: "${action}"`,
      supportedActions: Object.keys(handlers),
    });
  }

  return target(req, res);
};
