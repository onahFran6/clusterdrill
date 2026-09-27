# q101-45: Fix a Pod stuck in ImagePullBackOff

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-45-fix-imagepullbackoff-wrong-tag`

A Pod named `worker-app` (container also named `worker-app`, ServiceAccount `ci-deploy`) already
exists in namespace `q101-45-fix-imagepullbackoff-wrong-tag`. It is stuck and never becomes Ready.

Investigate with `kubectl describe pod/worker-app` and/or `kubectl get events`, then fix it
imperatively (delete and recreate is fine) so that:

- The Pod is still named `worker-app`, its container still named `worker-app`, still running as
  ServiceAccount `ci-deploy`, in this namespace.
- The image is corrected to the valid tag `nginx:1.25-alpine`.
- The Pod reaches `Running` and `Ready`.

## Hint

Search kubernetes.io/docs for **"troubleshoot applications imagepullbackoff"** - the "Debug Running
Pods" task page and `kubectl describe pod` output both explain how an `ImagePullBackOff` /
`ErrImagePull` status traces back to the exact image reference the kubelet failed to pull.
