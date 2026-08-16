# estodo feedback worker

This Worker receives bug reports from the app and forwards them to Resend.

Before deploying, add the Resend key as a secret:

```bash
npx wrangler secret put RESEND_API_KEY
npx wrangler deploy
```
