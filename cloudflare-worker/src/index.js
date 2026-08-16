const ALLOWED_HEADERS = {
  'Access-Control-Allow-Headers': 'content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Origin': '*',
  'Content-Type': 'application/json; charset=utf-8',
};

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: ALLOWED_HEADERS,
  });
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return new Response(null, { headers: ALLOWED_HEADERS });
    if (request.method !== 'POST') return json({ error: 'Method not allowed.' }, 405);

    let payload;
    try {
      payload = await request.json();
    } catch (_) {
      return json({ error: 'Invalid JSON.' }, 400);
    }

    const message = typeof payload.message === 'string' ? payload.message.trim() : '';
    const userEmail = typeof payload.userEmail === 'string' ? payload.userEmail.trim() : '';
    const displayName = typeof payload.displayName === 'string' ? payload.displayName.trim() : 'unknown';
    const type = payload.type === 'feature' ? 'feature' : 'bug';

    if (!message || message.length > 4000) {
      return json({ error: 'Message must be between 1 and 4000 characters.' }, 400);
    }
    if (userEmail && (userEmail.length > 320 || !userEmail.includes('@'))) {
      return json({ error: 'Invalid user email.' }, 400);
    }

    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'estodo <onboarding@resend.dev>',
        to: ['flashemirhan@gmail.com'],
        subject: type === 'feature'
          ? 'estodo özellik önerisi'
          : 'estodo bug bildirimi',
        text: [
          `Bildirim türü: ${type === 'feature' ? 'Özellik önerisi' : 'Bug bildirimi'}`,
          `Kullanıcı: ${displayName} <${userEmail || 'unknown'}>`,
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
