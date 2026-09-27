# q107-12: Debug a distroless pod that has no shell using a copied pod

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-12-debug-distroless-copy`

A running pod named `minimal-svc` (image `registry.k8s.io/pause:3.9`) already exists in namespace
`q107-12-debug-distroless-copy`.

Create a debug copy of `minimal-svc`:

- use `kubectl debug` with `--copy-to=minimal-svc-debug`
- add a new container named `debugger` using image `busybox:1.36` to the copy
- leave the original `minimal-svc` pod completely untouched

## Hint

Search kubernetes.io/docs for **"kubectl debug copy of pod"** - the debugging running pods task
page's "Copying a Pod while adding a new container" section covers exactly this case: an image
with no shell, where you debug a clone instead of the live pod. `kubectl exec` into `minimal-svc`
fails because the image ships no shell, and an ephemeral container on the existing pod does not
put a shell into the original container.
