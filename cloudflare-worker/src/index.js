const RESPONSE_HEADERS = {
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Origin': '*',
  'Content-Type': 'application/json; charset=utf-8',
};

const JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';
const MAX_MESSAGE_LENGTH = 4000;
const CLOCK_SKEW_SECONDS = 60;

let cachedKeys = { keys: new Map(), expiresAt: 0 };

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: RESPONSE_HEADERS,
  });
}

function base64UrlDecode(value) {
  const base64 = value.replace(/-/g, '+').replace(/_/g, '/');
  const padded = base64 + '='.repeat((4 - (base64.length % 4)) % 4);
  return Uint8Array.from(atob(padded), (char) => char.charCodeAt(0));
}

function decodeJsonPart(part) {
  return JSON.parse(new TextDecoder().decode(base64UrlDecode(part)));
}

async function signingKeys() {
  if (Date.now() < cachedKeys.expiresAt) return cachedKeys.keys;
  const response = await fetch(JWKS_URL);
  if (!response.ok) throw new Error(`JWKS fetch failed: ${response.status}`);
  const { keys } = await response.json();
  const maxAge = /max-age=(\d+)/.exec(response.headers.get('cache-control') ?? '');
  const imported = new Map();
  for (const jwk of keys) {
    imported.set(
      jwk.kid,
      await crypto.subtle.importKey(
        'jwk',
        jwk,
        { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
        false,
        ['verify'],
      ),
    );
  }
  cachedKeys = {
    keys: imported,
    expiresAt: Date.now() + (maxAge ? Number(maxAge[1]) : 3600) * 1000,
  };
  return imported;
}

/**
 * Verifies a Firebase Auth ID token and returns its claims, or null.
 * See https://firebase.google.com/docs/auth/admin/verify-id-tokens
 */
async function verifyIdToken(token, projectId) {
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  let header;
  let claims;
  try {
    header = decodeJsonPart(parts[0]);
    claims = decodeJsonPart(parts[1]);
  } catch (_) {
    return null;
  }
  if (header.alg !== 'RS256' || typeof header.kid !== 'string') return null;

  const key = (await signingKeys()).get(header.kid);
  if (!key) return null;
  const valid = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    key,
    base64UrlDecode(parts[2]),
    new TextEncoder().encode(`${parts[0]}.${parts[1]}`),
  );
  if (!valid) return null;

  const now = Math.floor(Date.now() / 1000);
  const expectedIssuer = `https://securetoken.google.com/${projectId}`;
  if (
    claims.aud !== projectId ||
    claims.iss !== expectedIssuer ||
    typeof claims.sub !== 'string' ||
    claims.sub.length === 0 ||
    claims.exp <= now - CLOCK_SKEW_SECONDS ||
    claims.iat > now + CLOCK_SKEW_SECONDS
  ) {
    return null;
  }
  return claims;
}

async function isRateLimited(limiter, key) {
  // The binding is optional so local `wrangler dev` works without it.
  if (!limiter) return false;
  const { success } = await limiter.limit({ key });
  return !success;
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return new Response(null, { headers: RESPONSE_HEADERS });
    if (request.method !== 'POST') return json({ error: 'Method not allowed.' }, 405);

    const ip = request.headers.get('cf-connecting-ip') ?? 'unknown';
    if (await isRateLimited(env.IP_LIMITER, ip)) {
      return json({ error: 'Too many requests.' }, 429);
    }

    const authorization = request.headers.get('authorization') ?? '';
    const token = authorization.startsWith('Bearer ') ? authorization.slice(7) : '';
    let claims = null;
    try {
      claims = token ? await verifyIdToken(token, env.FIREBASE_PROJECT_ID) : null;
    } catch (error) {
      console.error('ID token verification failed', String(error));
      return json({ error: 'Could not verify sign-in.' }, 503);
    }
    if (!claims) return json({ error: 'Sign-in required.' }, 401);

    if (await isRateLimited(env.USER_LIMITER, claims.sub)) {
      return json({ error: 'Too many requests.' }, 429);
    }

    let payload;
    try {
      payload = await request.json();
    } catch (_) {
      return json({ error: 'Invalid JSON.' }, 400);
    }

    const message = typeof payload.message === 'string' ? payload.message.trim() : '';
    const displayName =
      typeof payload.displayName === 'string' ? payload.displayName.trim().slice(0, 120) : 'unknown';
    const type = payload.type === 'feature' ? 'feature' : 'bug';
    // Identity comes from the verified token, never from the request body.
    const userEmail = typeof claims.email === 'string' ? claims.email : 'guest';

    if (!message || message.length > MAX_MESSAGE_LENGTH) {
      return json({ error: 'Message must be between 1 and 4000 characters.' }, 400);
    }

    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'estodo <onboarding@resend.dev>',
        to: [env.FEEDBACK_RECIPIENT],
        subject: type === 'feature'
          ? 'estodo özellik önerisi'
          : 'estodo bug bildirimi',
        text: [
          `Bildirim türü: ${type === 'feature' ? 'Özellik önerisi' : 'Bug bildirimi'}`,
          `Kullanıcı: ${displayName} <${userEmail}> (uid: ${claims.sub})`,
          '',
          message,
        ].join('\n'),
      }),
    });

    if (!response.ok) {
      console.error('Resend rejected feedback email', {
        status: response.status,
        body: await response.text(),
      });
      return json({ error: 'Email provider rejected the feedback.' }, 502);
    }

    return json({ ok: true });
  },
};
