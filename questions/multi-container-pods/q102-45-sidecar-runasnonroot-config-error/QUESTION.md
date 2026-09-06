# q102-45-sidecar-runasnonroot-config-error: runAsNonRoot Pod, sidecar with no runAsUser, never starts

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-45-sidecar-runasnonroot-config-error`

A Pod named `hardened-app` already exists in this namespace with
`spec.securityContext.runAsNonRoot: true` set at the Pod level (every
container must run as a non-root user), and two containers:

- `app` (busybox:1.36) explicitly sets its own
  `securityContext.runAsUser: 1000`, so it starts fine.
- `sidecar` (busybox:1.36) has **no** container-level `securityContext` at
  all.

`busybox:1.36`'s image defaults to running as `root` (UID `0`) when nothing
else says otherwise. Because `sidecar` never declares a `runAsUser` of its
own, the kubelet cannot prove it won't run as root - inheriting
`runAsNonRoot: true` from the Pod is not enough by itself - so it refuses
to create `sidecar` at all: `kubectl get pod hardened-app` shows `1/2`, and
`sidecar` sits waiting with reason `CreateContainerConfigError` and the
message `container has runAsNonRoot and image will run as root`. `app` is
unaffected.

Fix `sidecar` so it also runs as a non-root user - add
`securityContext.runAsUser: 1000` to `sidecar`'s container spec (matching
`app`). Do not change the Pod-level `runAsNonRoot`, `app`'s
`securityContext`, or either container's image or command. This field is
immutable on a running Pod - delete and recreate `hardened-app` with the
fix applied, keeping every other field unchanged. Once fixed,
`hardened-app` must reach `2/2 Running`.

## Hint

Search kubernetes.io/docs for **"configure a security context for a pod or
container"** - the Security Context concept page explains that
`runAsNonRoot: true` only tells Kubernetes to refuse to start a container
whose EFFECTIVE user would be root - it does not, by itself, choose a
non-root user; `runAsUser` is what actually does that, at the Pod level or
per-container.
