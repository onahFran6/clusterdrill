# q102-44-init-container-secret-defaultmode-too-restrictive: Secret volume's defaultMode blocks the non-root init container that needs it

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-44-init-container-secret-defaultmode-too-restrictive`

A Secret named `tls-cert` (key `tls.key`) and a Pod named
`cert-staging-app` already exist in this namespace:

- An init container `cert-loader` (busybox:1.36) runs as
  `securityContext.runAsUser: 1000` (a deliberate hardening choice - do not
  remove it) and copies `tls-cert`'s `tls.key` from the mounted Secret
  volume at `/secret-in` into a shared `emptyDir` volume `handoff`, at
  `/handoff/tls.key`, so the main container never needs direct Secret
  access.
- The main container `app` (busybox:1.36) mounts the same `handoff` volume
  and expects to find `/handoff/tls.key` there.

The Secret volume's `defaultMode` is `0000` - unreadable by anyone except
the file's own `root:root` owner. `cert-loader` runs as UID `1000`, not
root, so its `cp` fails with `Permission denied`. That error is silently
redirected away and `cert-loader` still exits `0` - nothing crashes,
`kubectl get pod cert-staging-app` shows `1/1 Running` right away - but
`/handoff/tls.key` was never actually created.

Fix the Secret volume's `defaultMode` so `cert-loader` (still running as
UID `1000`) can actually read it: set it to `0444` (readable by anyone,
writable by no one). Do not change `cert-loader`'s `runAsUser`, either
container's image or command, or the Secret itself. This field is
immutable on a running Pod - delete and recreate `cert-staging-app` with
the fix applied, keeping every other field unchanged. Once fixed,
`/handoff/tls.key` inside `app` must contain exactly `sekret-key-value-9931`.

## Hint

Search kubernetes.io/docs for **"secrets"** - the Secrets concept page's
"Secret files permissions" section shows how a Secret volume's
`defaultMode` controls the Unix file permission bits on the files it
projects, and that this is checked against the container's actual
`runAsUser`, not root, once one is set.
