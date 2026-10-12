module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method Not Allowed. Use POST.' });
  }

  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Missing Authorization header. Expected Bearer <access_token>.',
      });
    }

    const accessToken = authHeader.substring(7);
    const {
      title,
      description = '',
      tags = [],
      privacyStatus = 'unlisted', // 'private', 'unlisted', 'public'
      publishAt, // RFC 3339 formatted ISO string for scheduled publish
      madeForKids = false,
      categoryId = '22', // People & Blogs default
    } = req.body || {};

    if (!title || title.trim().length === 0) {
      return res.status(400).json({ error: 'Video title is required.' });
    }

    if (title.length > 100) {
      return res.status(400).json({
        error: `Video title exceeds YouTube limit of 100 characters (length: ${title.length}).`,
      });
    }

    if (description.length > 5000) {
      return res.status(400).json({
        error: `Video description exceeds YouTube limit of 5,000 characters (length: ${description.length}).`,
      });
    }

    // Prepare metadata according to official YouTube Data API v3 specification
    const videoMetadata = {
      snippet: {
        title: title.trim(),
        description: description.trim(),
        tags: Array.isArray(tags) ? tags : [],
        categoryId: categoryId.toString(),
      },
      status: {
        privacyStatus: privacyStatus.toLowerCase(),
        selfDeclaredMadeForKids: Boolean(madeForKids),
      },
    };

    // If scheduled publish date is provided, YouTube requires privacyStatus to be 'private'
    if (publishAt) {
      videoMetadata.status.privacyStatus = 'private';
      videoMetadata.status.publishAt = new Date(publishAt).toISOString();
    }

    // Initiate Resumable Upload Session with YouTube
    const ytInitRes = await fetch(
      'https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json; charset=UTF-8',
          'X-Upload-Content-Type': req.headers['x-upload-content-type'] || 'video/*',
        },
        body: JSON.stringify(videoMetadata),
      }
    );

    if (!ytInitRes.ok) {
      const errBody = await ytInitRes.json().catch(() => ({}));
      console.error('[YouTube Upload Session Error]', ytInitRes.status, errBody);
      return res.status(ytInitRes.status).json({
        error: errBody.error?.message || 'Failed to initiate YouTube resumable upload session.',
        details: errBody,
      });
    }

    // Google returns the upload URL in the Location response header
    const uploadUrl = ytInitRes.headers.get('location');

    if (!uploadUrl) {
      return res.status(500).json({
        error: 'YouTube API did not return a resumable upload location header.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'YouTube resumable upload session created successfully.',
      uploadUrl: uploadUrl,
      metadata: videoMetadata,
    });
  } catch (err) {
    console.error('[YouTube Upload Exception]', err);
    return res.status(500).json({
      error: 'Internal server error while initializing YouTube upload session.',
      message: err.message,
    });
  }
};
