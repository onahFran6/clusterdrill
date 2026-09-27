# q102-47: Give a readOnlyRootFilesystem sidecar a writable scratch volume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-47-readonlyrootfs-sidecar-needs-scratch-volume`

A Pod named `hardened-lock-app` already exists in this namespace with two
containers:

- `app` (busybox:1.36) - idles.
- `lock-manager` (busybox:1.36) - hardened with
  `securityContext.readOnlyRootFilesystem: true` (do not remove it), and
  repeatedly tries to write a lock file to `/tmp/lock.txt`.

`kubectl get pod hardened-lock-app` shows `2/2 Running`, but `lock-manager`
never successfully writes its lock file - every write against the read-only
root filesystem fails.

Fix `lock-manager` by adding a dedicated writable `emptyDir` volume named
`scratch`, mounted at `/tmp`, so it has somewhere to write while the rest of
its filesystem stays read-only. Do not remove `readOnlyRootFilesystem: true`,
and do not change either container's image or command, or touch `app`. This
field is immutable on a running Pod - delete and recreate `hardened-lock-app`
with the fix applied, keeping every other field unchanged. Once fixed,
`/tmp/lock.txt` inside `lock-manager` must contain exactly `locked`.

## Hint

Search kubernetes.io/docs for **"configure a security context for a pod or
container"** - the Security Context concept page's `readOnlyRootFilesystem`
example shows that a container hardened this way still needs an explicit
writable volume (commonly an `emptyDir` mounted at `/tmp`) for any scratch
data it legitimately needs to write.
