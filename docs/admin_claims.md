# Admin Claims Helper

Use this helper to safely grant/revoke Firebase custom claim `role=admin`.

## Prerequisites

- Firebase CLI authenticated (`firebase login`)
- Access to target Firebase project
- Node.js installed

## Setup

```bash
cd tools/admin_claims
npm install
```

## Grant admin role

By email:

```bash
node set_admin_claim.mjs grant --project studentmove-dev --email user@example.com
```

By uid:

```bash
node set_admin_claim.mjs grant --project studentmove-prod-f56f6 --uid USER_UID
```

## Revoke admin role

```bash
node set_admin_claim.mjs revoke --project studentmove-prod-f56f6 --uid USER_UID
```

## Notes

- The script preserves existing custom claims and only updates `role`.
- If revoking and `role` is already not `admin`, claims remain unchanged.
