module.exports = async function handler(req, res) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Missing Authorization header. Expected Bearer <access_token>.',
      });
    }

    const accessToken = authHeader.substring(7);

    const ytRes = await fetch(
      'https://www.googleapis.com/youtube/v3/channels?part=snippet,statistics,contentDetails&mine=true',
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
        error: ytData.error?.message || 'Failed to query YouTube channels.',
        details: ytData,
      });
    }

    if (!ytData.items || ytData.items.length === 0) {
      return res.status(200).json({
        success: true,
        channels: [],
        message: 'No YouTube channels found under this Google account.',
      });
    }

    const channels = ytData.items.map((item) => {
      const customUrl = item.snippet.customUrl || '';
      const handle = customUrl
        ? (customUrl.startsWith('@') ? customUrl : `@${customUrl}`)
        : `@${item.snippet.title.replace(/\s+/g, '').toLowerCase()}`;

      return {
        id: item.id,
        title: item.snippet.title,
        handle: handle,
        description: item.snippet.description,
        avatarUrl:
          item.snippet.thumbnails?.medium?.url ||
          item.snippet.thumbnails?.default?.url ||
          '',
        subscriberCount: parseInt(item.statistics?.subscriberCount || '0', 10),
        videoCount: parseInt(item.statistics?.videoCount || '0', 10),
      };
    });

    return res.status(200).json({
      success: true,
      channels: channels,
    });
  } catch (err) {
    console.error('[YouTube Channels API Error]', err);
    return res.status(500).json({
      error: 'Internal server error while querying YouTube channels',
      message: err.message,
    });
  }
};
