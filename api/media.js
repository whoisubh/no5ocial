const crypto = require('crypto');

/**
 * Computes HMAC-SHA256
 */
function hmac(key, string) {
  return crypto.createHmac('sha256', key).update(string).digest();
}

/**
 * Computes SHA-256 hex digest
 */
function hash(string) {
  return crypto.createHash('sha256').update(string).digest('hex');
}

/**
 * Generates an AWS Signature Version 4 presigned PUT URL for Cloudflare R2
 * Compatible with pure Node.js runtime (zero npm dependencies).
 */
function generateR2PresignedPutUrl({
  accountId,
  bucket,
  key,
  accessKeyId,
  secretAccessKey,
  expiresInSeconds = 300,
}) {
  const service = 's3';
  const region = 'auto';
  const method = 'PUT';
  const host = `${accountId}.r2.cloudflarestorage.com`;
  const endpoint = `https://${host}`;

  const canonicalUri = `/${bucket}/${key.split('/').map(encodeURIComponent).join('/')}`;

  const now = new Date();
  const amzDate = now.toISOString().replace(/[:-]|\.\d{3}/g, '');
  const dateStamp = amzDate.slice(0, 8);

  const queryParams = {
    'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
    'X-Amz-Credential': `${accessKeyId}/${dateStamp}/${region}/${service}/aws4_request`,
    'X-Amz-Date': amzDate,
    'X-Amz-Expires': expiresInSeconds.toString(),
    'X-Amz-SignedHeaders': 'host',
  };

  const sortedKeys = Object.keys(queryParams).sort();
  const canonicalQueryString = sortedKeys
    .map((k) => `${encodeURIComponent(k)}=${encodeURIComponent(queryParams[k])}`)
    .join('&');

  const canonicalHeaders = `host:${host}\n`;
  const signedHeaders = 'host';
  const payloadHash = 'UNSIGNED-PAYLOAD';

  const canonicalRequest = [
    method,
    canonicalUri,
    canonicalQueryString,
    canonicalHeaders,
    signedHeaders,
    payloadHash,
  ].join('\n');

  const credentialScope = `${dateStamp}/${region}/${service}/aws4_request`;
  const stringToSign = [
    'AWS4-HMAC-SHA256',
    amzDate,
    credentialScope,
    hash(canonicalRequest),
  ].join('\n');

  const kDate = hmac(`AWS4${secretAccessKey}`, dateStamp);
  const kRegion = hmac(kDate, region);
  const kService = hmac(kRegion, service);
  const kSigning = hmac(kService, 'aws4_request');
  const signature = hmac(kSigning, stringToSign).toString('hex');

  const finalQueryString = `${canonicalQueryString}&X-Amz-Signature=${signature}`;
  return `${endpoint}${canonicalUri}?${finalQueryString}`;
}

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }

  const accountId = (
    process.env.R2_ACCOUNT_ID ||
    process.env.CLOUDFLARE_ACCOUNT_ID ||
    ''
  ).trim();

  const bucket = (
    process.env.R2_BUCKET_NAME ||
    'no5ocial-media'
  ).trim();

  const accessKeyId = (
    process.env.R2_ACCESS_KEY_ID ||
    ''
  ).trim();

  const secretAccessKey = (
    process.env.R2_SECRET_ACCESS_KEY ||
    ''
  ).trim();

  const publicDomain = (
    process.env.R2_PUBLIC_DOMAIN ||
    'https://pub-5e5439b590cb4d04a5e4f444072646d0.r2.dev'
  ).trim().replace(/\/+$/, '');

  if (!accountId || !accessKeyId || !secretAccessKey) {
    return res.status(503).json({
      error: 'R2 storage credentials not configured on server.',
      configured: false,
    });
  }

  try {
    const rawFilename = String(req.query.filename || req.body?.filename || 'media').trim();
    const cleanFilename = rawFilename.replace(/[^a-zA-Z0-9._-]/g, '_');
    const ext = cleanFilename.includes('.') ? cleanFilename.split('.').pop().toLowerCase() : 'jpg';
    const timestamp = Date.now();
    const nonce = crypto.randomBytes(6).toString('hex');
    const key = `uploads/${timestamp}_${nonce}_${cleanFilename}`;

    const uploadUrl = generateR2PresignedPutUrl({
      accountId,
      bucket,
      key,
      accessKeyId,
      secretAccessKey,
      expiresInSeconds: 600, // 10 minutes
    });

    const publicUrl = `${publicDomain}/${key}`;

    return res.status(200).json({
      success: true,
      uploadUrl,
      publicUrl,
      key,
      expiresIn: 600,
    });
  } catch (err) {
    return res.status(500).json({
      error: 'Failed to generate presigned upload URL',
      details: err.message,
    });
  }
};
