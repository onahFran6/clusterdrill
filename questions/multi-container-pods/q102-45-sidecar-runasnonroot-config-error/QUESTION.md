# q102-45: Start a sidecar under a runAsNonRoot Pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-45-sidecar-runasnonroot-config-error`

A Pod named `hardened-app` already exists in this namespace with
`spec.securityContext.runAsNonRoot: true` at the Pod level, and two containers:

- `app` (busybox:1.36) explicitly sets `securityContext.runAsUser: 1000`, so it
  starts fine.
- `sidecar` (busybox:1.36) has no container-level `securityContext` at all.

`kubectl get pod hardened-app` shows `1/2`, and `sidecar` sits waiting with
reason `CreateContainerConfigError` and a message about `runAsNonRoot` and the
image running as root. `app` is unaffected.

Fix `sidecar` so it also runs as a non-root user - add
`securityContext.runAsUser: 1000` to `sidecar`'s container spec (matching
`app`). Do not change the Pod-level `runAsNonRoot`, `app`'s `securityContext`,
or either container's image or command. This field is immutable on a running
Pod - delete and recreate `hardened-app` with the fix applied, keeping every
other field unchanged. Once fixed, `hardened-app` must reach `2/2 Running`.

## Hint

Search kubernetes.io/docs for **"configure a security context for a pod or
container"** - the Security Context concept page explains that
`runAsNonRoot: true` only tells Kubernetes to refuse to start a container
whose EFFECTIVE user would be root - it does not, by itself, choose a
non-root user; `runAsUser` is what actually does that, at the Pod level or
per-container.
