# estodo feedback worker

This Worker receives bug reports and feature suggestions from the app and
forwards them to Resend.

Requests must carry a Firebase Auth ID token (`Authorization: Bearer <token>`);
the sender's email and uid are taken from the verified token, not the request
body. Requests are rate limited per IP and per user (see `wrangler.toml`).

Before deploying, add the Resend key as a secret:

```bash
npx wrangler secret put RESEND_API_KEY
npx wrangler deploy
```

Deploy order: ship the app version that sends the ID token first. Older app
builds send no token and get `401` from this Worker.
