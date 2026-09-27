# q106-40: Override a ServiceAccount's automount setting at the Pod level

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-40-serviceaccount-automount-pod-override-true`

A ServiceAccount named `token-needer` already exists with `automountServiceAccountToken: false`.

Create a Pod named `token-client` that uses ServiceAccount `token-needer` and still has its API
token auto-mounted. Set `automountServiceAccountToken: true` on the Pod. Do not change the
ServiceAccount. Image `busybox:1.36` with command `sleep 3600` is fine.

## Hint

Search kubernetes.io/docs for **"opt out of API credential automounting"** - the service account
configuration task page explains that a Pod-level `automountServiceAccountToken` setting takes
precedence over the ServiceAccount's own setting.
