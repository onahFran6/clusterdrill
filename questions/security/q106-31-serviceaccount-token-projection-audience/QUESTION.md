# q106-31-serviceaccount-token-projection-audience: Configure a projected ServiceAccount token volume with a custom audience and expirationSeconds

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-31-serviceaccount-token-projection-audience`

Pod `secrets-agent` already exists in namespace
`q106-31-serviceaccount-token-projection-audience` (image `busybox:1.36`, command `sleep 3600`,
ServiceAccount `vault-client`). It currently has only the default automounted ServiceAccount
token. A sidecar needs a short-lived token scoped to a specific audience instead.

Edit the pod so that:

- it no longer automounts the default ServiceAccount token
  (`automountServiceAccountToken: false` on the pod spec), and
- it mounts a `projected` volume at `/var/run/secrets/tokens` with a `serviceAccountToken` source
  of `audience: vault`, `expirationSeconds: 600`, and `path: vault-token`.

You may delete and recreate the pod under the same name. A file named `vault-token` must be
present under `/var/run/secrets/tokens`.

## Hint

Search kubernetes.io/docs for **"serviceaccount token volume projection"** - the ServiceAccount
concept page shows a full pod manifest with `audience`, `expirationSeconds`, and `path` under a
projected volume's `serviceAccountToken` source. Confirm with
`kubectl exec secrets-agent -- ls /var/run/secrets/tokens`.
