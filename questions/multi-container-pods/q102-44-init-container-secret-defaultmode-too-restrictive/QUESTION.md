# q102-44: Let a non-root init container read a Secret volume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-44-init-container-secret-defaultmode-too-restrictive`

A Secret named `tls-cert` (key `tls.key`) and a Pod named `cert-staging-app`
already exist in this namespace:

- An init container `cert-loader` (busybox:1.36) runs as
  `securityContext.runAsUser: 1000` (do not remove it) and copies `tls-cert`'s
  `tls.key` from the mounted Secret volume at `/secret-in` into a shared
  `emptyDir` volume `handoff`, at `/handoff/tls.key`.
- The main container `app` (busybox:1.36) mounts the same `handoff` volume and
  expects `/handoff/tls.key`.

`cert-loader` exits `0` and the Pod shows `1/1 Running`, but `/handoff/tls.key`
was never created - the init container could not read the Secret volume files.

Fix the Secret volume's `defaultMode` so `cert-loader` (still running as UID
`1000`) can read it: set it to `0444`. Do not change `cert-loader`'s
`runAsUser`, either container's image or command, or the Secret itself. This
field is immutable on a running Pod - delete and recreate `cert-staging-app`
with the fix applied, keeping every other field unchanged. Once fixed,
`/handoff/tls.key` inside `app` must contain exactly `sekret-key-value-9931`.

## Hint

Search kubernetes.io/docs for **"secrets"** - the Secrets concept page's
"Secret files permissions" section shows how a Secret volume's
`defaultMode` controls the Unix file permission bits on the files it
projects, and that this is checked against the container's actual
`runAsUser`, not root, once one is set.
