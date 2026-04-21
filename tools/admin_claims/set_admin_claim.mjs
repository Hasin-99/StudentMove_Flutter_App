import fs from 'node:fs';
import path from 'node:path';
import admin from 'firebase-admin';

function usage() {
  console.log('Usage:');
  console.log('  node set_admin_claim.mjs <grant|revoke> --project <projectId> (--uid <uid> | --email <email>)');
  console.log('');
  console.log('Examples:');
  console.log('  node set_admin_claim.mjs grant --project studentmove-dev --email user@example.com');
  console.log('  node set_admin_claim.mjs revoke --project studentmove-prod-f56f6 --uid abc123');
}

function parseArgs(argv) {
  const args = { action: argv[2], project: '', uid: '', email: '', role: 'super_admin' };
  for (let i = 3; i < argv.length; i += 1) {
    const key = argv[i];
    const val = argv[i + 1] ?? '';
    if (key === '--project') args.project = val;
    if (key === '--uid') args.uid = val;
    if (key === '--email') args.email = val;
    if (key === '--role') args.role = val;
    if (key.startsWith('--')) i += 1;
  }
  return args;
}

function parseServiceAccount(raw) {
  if (!raw) return null;
  const attempts = [raw, raw.replace(/\\"/g, '"')];
  for (const candidate of attempts) {
    try {
      const parsed = JSON.parse(candidate);
      if (typeof parsed.private_key === 'string') {
        parsed.private_key = parsed.private_key.replace(/\\n/g, '\n');
      }
      return parsed;
    } catch {}
  }
  return null;
}

function loadEnvValueFromAdminEnv(key) {
  const envPath = path.resolve(process.cwd(), '../../admin/.env');
  if (!fs.existsSync(envPath)) return '';
  const raw = fs.readFileSync(envPath, 'utf8');
  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#') || !trimmed.includes('=')) continue;
    const idx = trimmed.indexOf('=');
    const k = trimmed.slice(0, idx).trim();
    if (k !== key) continue;
    let v = trimmed.slice(idx + 1).trim();
    if (
      (v.startsWith('"') && v.endsWith('"')) ||
      (v.startsWith("'") && v.endsWith("'"))
    ) {
      v = v.slice(1, -1);
    }
    return v;
  }
  return '';
}

const { action, project, uid, email, role } = parseArgs(process.argv);
if (!['grant', 'revoke'].includes(action) || !project || (!uid && !email)) {
  usage();
  process.exit(1);
}

const rawServiceAccount =
  process.env.FIREBASE_SERVICE_ACCOUNT_JSON ||
  loadEnvValueFromAdminEnv('FIREBASE_SERVICE_ACCOUNT_JSON');
const serviceAccount = parseServiceAccount(rawServiceAccount);

admin.initializeApp(
  serviceAccount
    ? { credential: admin.credential.cert(serviceAccount), projectId: project }
    : { projectId: project },
);
const auth = admin.auth();

async function resolveUid() {
  if (uid) return uid;
  const user = await auth.getUserByEmail(email);
  return user.uid;
}

const targetUid = await resolveUid();
const user = await auth.getUser(targetUid);
const currentClaims = user.customClaims || {};
const nextClaims = { ...currentClaims };

if (action === 'grant') {
  nextClaims.role = role || 'super_admin';
} else {
  if (nextClaims.role) {
    delete nextClaims.role;
  }
}

await auth.setCustomUserClaims(targetUid, nextClaims);

console.log(
  `${action === 'grant' ? 'Granted' : 'Revoked'} role claim for uid=${targetUid} in project=${project}. role=${nextClaims.role ?? 'none'}`,
);
