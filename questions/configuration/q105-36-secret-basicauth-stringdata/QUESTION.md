# q105-36: Wire basic-auth credentials into a proxy pod

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-36-secret-basicauth-stringdata`

A running Pod named `auth-proxy` (image `nginx:1.25-alpine`) exists in namespace
`q105-36-secret-basicauth-stringdata`, with no Secret yet.

Create a Secret named `proxy-creds` with `type: kubernetes.io/basic-auth`, writing its two
keys under `stringData` (plain text) rather than pre-encoding them into `data` yourself:

- `username`: `svc-proxy`
- `password`: `Tr0ub4dor&3`

Then edit the Pod so its container gets two environment variables sourced from that Secret via
`secretKeyRef`: `AUTH_USER` from the `username` key, and `AUTH_PASS` from the `password` key.
Recreate the Pod for the change to take effect.

## Hint

Search kubernetes.io/docs for **"secret types"** - the Secrets concept page's "Basic
authentication Secret" section shows the `kubernetes.io/basic-auth` type's required
`username`/`password` keys and how `stringData` lets you write plain text instead of pre-encoding
base64 by hand.
