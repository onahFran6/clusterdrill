# q106-31-serviceaccount-token-projection-audience: Configure a projected ServiceAccount token volume with a custom audience and expirationSeconds

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-31-serviceaccount-token-projection-audience`

Pod `secrets-agent` (already created by `setup.sh` in namespace
`q106-31-serviceaccount-token-projection-audience`, image `busybox:1.36`, command `sleep 3600`,
running under ServiceAccount `vault-client`) currently receives only the default automounted
ServiceAccount token. A sidecar tool the team is integrating requires a short-lived token scoped
to a specific audience instead.

Edit the pod so that:

- it no longer automounts the default ServiceAccount token
  (`automountServiceAccountToken: false` at the pod spec level), and
- it instead mounts a `projected` volume at `/var/run/secrets/tokens` containing a
  `serviceAccountToken` source with `audience: vault`, `expirationSeconds: 600`, and
  `path: vault-token`.

You may delete and recreate the pod under the same name if needed. After the fix,
`kubectl exec secrets-agent -- ls /var/run/secrets/tokens` must show a file named `vault-token`.

## Hint

Search kubernetes.io/docs for **"serviceaccount token volume projection"** - the ServiceAccount
concept page shows a full pod manifest example with `audience`, `expirationSeconds`, and `path`
under a projected volume's `serviceAccountToken` source.
