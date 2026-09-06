# q106-40: Override a ServiceAccount's automount setting at the Pod level

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-40-serviceaccount-automount-pod-override-true`

`setup.sh` already created a ServiceAccount named `token-needer` with
`automountServiceAccountToken: false`. Create a Pod named `token-client` (any suitable image, e.g.
`busybox:1.36` running `sleep 3600`) that uses ServiceAccount `token-needer` but still gets its API
token auto-mounted, by setting `automountServiceAccountToken: true` at the **Pod** level - do not
change the ServiceAccount.

## Hint

Search kubernetes.io/docs for **"opt out of API credential automounting"** - the service account
configuration task page explains that a Pod-level `automountServiceAccountToken` setting takes
precedence over the ServiceAccount's own setting.
