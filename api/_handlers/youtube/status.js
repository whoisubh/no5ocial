module.exports = async function handler(req, res) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Missing Authorization header. Expected Bearer <access_token>.',
      });
    }

    const accessToken = authHeader.substring(7);
    const videoId = req.query.id;

    if (!videoId) {
      return res.status(400).json({ error: 'Missing required query parameter "id" (Video ID).' });
    }

    const ytRes = await fetch(
      `https://www.googleapis.com/youtube/v3/videos?part=snippet,status,processingDetails&id=${encodeURIComponent(videoId)}`,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          Accept: 'application/json',
        },
      }
    );

    const ytData = await ytRes.json();

    if (!ytRes.ok || ytData.error) {
      return res.status(ytRes.status || 400).json({
        error: ytData.error?.message || 'Failed to inspect YouTube video status.',
        details: ytData,
      });
    }

    if (!ytData.items || ytData.items.length === 0) {
      return res.status(404).json({
        error: `Video with ID "${videoId}" not found.`,
      });
    }

    const item = ytData.items[0];
    const status = item.status || {};
    const processingDetails = item.processingDetails || {};

    return res.status(200).json({
      success: true,
      videoId: videoId,
      videoUrl: `https://youtu.be/${videoId}`,
      uploadStatus: status.uploadStatus, // 'uploaded', 'processed', 'failed', 'rejected'
      privacyStatus: status.privacyStatus,
      processingStatus: processingDetails.processingStatus, // 'processing', 'succeeded', 'failed', 'terminated'
      processingProgress: processingDetails.processingProgress,
      failureReason: status.failureReason || processingDetails.processingFailureReason,
      rejectionReason: status.rejectionReason,
    });
  } catch (err) {
    console.error('[YouTube Video Status Exception]', err);
    return res.status(500).json({
      error: 'Internal server error while inspecting YouTube video status.',
      message: err.message,
    });
  }
};
