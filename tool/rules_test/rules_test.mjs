import assert from 'node:assert/strict';
const base = `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/demo-estodo/databases/(default)/documents`;
const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const token = (uid) => `${b64({ alg: 'none' })}.${b64({ sub: uid, user_id: uid, aud: 'demo-estodo', iss: 'https://securetoken.google.com/demo-estodo', firebase: { sign_in_provider: 'password' } })}.`;
const val = (v) => v === null ? { nullValue: null } : typeof v === 'string' ? { stringValue: v } : typeof v === 'boolean' ? { booleanValue: v }
  : Number.isInteger(v) ? { integerValue: String(v) } : Array.isArray(v) ? { arrayValue: { values: v.map(val) } }
  : { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, val(x)])) } };
const put = (path, data, uid) => fetch(`${base}/${path}`, { method: 'PATCH', headers: { Authorization: `Bearer ${uid ? token(uid) : 'none'}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({ fields: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, val(v)])) }) }).then((r) => r.status);
const task = { iconKey: null, colorValue: null, isHabit: false, durationMinutes: null, id: 't', userId: 'u', title: 'x', priority: 'low', isCompleted: false, isImportant: false, isMyDay: false, notes: null, steps: [], tags: [], recurrence: null, listId: null };
assert.equal(await put('users/u/tasks/t', task, 'u'), 200, 'valid task');
assert.equal(await put('users/u/tasks/t', { ...task, notes: 'n', listId: 'l', tags: ['a'], steps: [{ title: 's', done: false }], recurrence: { type: 'daily' } }, 'u'), 200, 'filled task');
assert.equal(await put('users/u/tasks/t', { ...task, notes: 'x'.repeat(10001) }, 'u'), 403, 'notes too long');
assert.equal(await put('users/u/tasks/t', { ...task, tags: Array(51).fill('a') }, 'u'), 403, 'too many tags');
assert.equal(await put('users/u/tasks/t', { ...task, recurrence: 'daily' }, 'u'), 403, 'bad recurrence');
const minimal = { ...task }; delete minimal.notes; delete minimal.steps; delete minimal.tags; delete minimal.recurrence; delete minimal.listId;
assert.equal(await put('users/u/tasks/t2', minimal, 'u'), 200, 'missing optional fields');
assert.equal(await put('users/u/tasks/t', task, 'other'), 403, 'other user');
assert.equal(await put('mail/m', { to: ['flashemirhan@gmail.com'], message: { subject: 's', text: 't' } }, 'u'), 403, 'mail closed');
assert.equal(await put('feedback/f', { message: 'm', recipientEmail: 'flashemirhan@gmail.com', status: 'new' }, 'u'), 403, 'feedback closed');
assert.equal(await put('share_lookup/l', { ownerId: 'u', listId: 'l' }, 'u'), 403, 'share create closed');
assert.equal(await put('users/u/list_memberships/l', { ownerId: 'x', listId: 'l' }, 'u'), 403, 'membership create closed');
console.log('rules tests passed');
