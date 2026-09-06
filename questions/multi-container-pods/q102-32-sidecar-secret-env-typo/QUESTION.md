# q102-32-sidecar-secret-env-typo: Sidecar's Secret reference has a typo, never starts

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-32-sidecar-secret-env-typo`

A Pod named `token-reporter` already exists in this namespace with two containers:

- `app` (busybox:1.36) - the main application container, unrelated to this
  bug, just idles.
- `reporter` (busybox:1.36) - a sidecar that is supposed to load a Secret
  named `api-credentials` via `envFrom` and write its `API_TOKEN` key to
  `/report/status.txt` for outside tooling to read.

A Secret named `api-credentials` with key `API_TOKEN` already exists in this
namespace. `reporter`'s `envFrom[0].secretRef.name` was typed with a typo
(`api-credential`, missing the trailing `s`), so it does not match the real
Secret. Kubernetes refuses to create a container whose `envFrom` references
a Secret that does not exist, so `reporter` never starts at all -
`kubectl get pod token-reporter` shows `1/2`, and `reporter` sits waiting
with reason `CreateContainerConfigError` (visible via
`kubectl describe pod token-reporter`). `app` is unaffected and keeps
running fine.

Fix `reporter`'s `envFrom[0].secretRef.name` so it references the real
Secret `api-credentials`. Do not change the Secret, either container's
image, or `app`'s command. This field is immutable on a running Pod -
delete and recreate `token-reporter` with the fix applied, keeping every
other field unchanged. Once fixed, `token-reporter` must reach `2/2
Running`, and `/report/status.txt` inside `reporter` must contain the real
token value from the Secret's `API_TOKEN` key.

## Hint

Search kubernetes.io/docs for **"envFrom"** - the "Define Container
Environment Variables Using Secret Data" task and the Secrets concept page
show how `envFrom[].secretRef.name` populates every key in a Secret as
environment variables in one container, and what happens when that Secret
does not exist.
