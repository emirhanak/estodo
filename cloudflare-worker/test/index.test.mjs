import assert from 'node:assert/strict';
const { privateKey, publicKey } = await crypto.subtle.generateKey(
  { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' }, true, ['sign', 'verify']);
const jwk = { ...(await crypto.subtle.exportKey('jwk', publicKey)), kid: 'k1', alg: 'RS256' };
const b64 = (o) => Buffer.from(typeof o === 'string' ? o : JSON.stringify(o)).toString('base64url');
async function sign(claims, kid = 'k1') {
  const data = `${b64({ alg: 'RS256', kid })}.${b64(claims)}`;
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', privateKey, new TextEncoder().encode(data));
  return `${data}.${Buffer.from(sig).toString('base64url')}`;
}
let sent = [];
globalThis.fetch = async (url, init) => {
  if (String(url).includes('googleapis')) return new Response(JSON.stringify({ keys: [jwk] }), { headers: { 'cache-control': 'max-age=100' } });
  sent.push(JSON.parse(init.body)); return new Response('{}');
};
const worker = (await import('../src/index.js')).default;
const now = Math.floor(Date.now() / 1000);
const good = { aud: 'p', iss: 'https://securetoken.google.com/p', sub: 'u1', email: 'a@b.c', iat: now, exp: now + 3600 };
const env = { FIREBASE_PROJECT_ID: 'p', FEEDBACK_RECIPIENT: 'x@y.z', RESEND_API_KEY: 'k' };
const call = (token, body = { message: 'hi', userEmail: 'spoof@evil' }) => worker.fetch(new Request('https://w', {
  method: 'POST', headers: token ? { authorization: `Bearer ${token}` } : {}, body: JSON.stringify(body) }), env);
assert.equal((await call(null)).status, 401);
assert.equal((await call(await sign({ ...good, aud: 'other' }))).status, 401);
assert.equal((await call(await sign({ ...good, exp: now - 600 }))).status, 401);
assert.equal((await call(await sign(good, 'unknown'))).status, 401);
const tampered = (await sign(good)).split('.'); tampered[1] = b64({ ...good, sub: 'u2' });
assert.equal((await call(tampered.join('.'))).status, 401);
assert.equal((await call(await sign(good), { message: '' })).status, 400);
const ok = await call(await sign(good));
assert.equal(ok.status, 200);
assert.equal(sent.length, 1);
assert.ok(sent[0].text.includes('a@b.c') && !sent[0].text.includes('spoof'));
assert.deepEqual(sent[0].to, ['x@y.z']);
let n = 0; env.USER_LIMITER = { limit: async () => ({ success: ++n <= 1 }) };
assert.equal((await call(await sign(good))).status, 200);
assert.equal((await call(await sign(good))).status, 429);
console.log('worker tests passed');
