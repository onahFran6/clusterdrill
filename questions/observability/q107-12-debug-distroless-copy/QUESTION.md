# q107-12: Debug a distroless pod that has no shell using a copied pod

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-12-debug-distroless-copy`

`setup.sh` already created a running pod named `minimal-svc` (image `registry.k8s.io/pause:3.9`) in
namespace `q107-12-debug-distroless-copy`. This image ships no shell and no debugging tools at all -
`kubectl exec ... -- sh` fails outright - so an ephemeral container attached to the *existing* pod
would still have no shell in the original container to inspect via shared process namespace tricks
that assume one exists. Instead, create a full copy of the pod with an extra debug container added.

Create a debug copy of `minimal-svc`:

- use `kubectl debug` with `--copy-to=minimal-svc-debug`
- add a new container named `debugger` using image `busybox:1.36` to the copy
- leave the original `minimal-svc` pod completely untouched

## Hint

Search kubernetes.io/docs for **"kubectl debug copy of pod"** - the debugging running pods task
page's "Copying a Pod while adding a new container" section covers exactly this case: an image
with no shell, where you debug a clone instead of the live pod.
