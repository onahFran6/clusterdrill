# q101-45-fix-imagepullbackoff-wrong-tag: Diagnose and fix a pod stuck in ImagePullBackOff from a typo'd image tag

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-45-fix-imagepullbackoff-wrong-tag`

`setup.sh` already created a Pod named `worker-app` with a single container also named
`worker-app`, running as ServiceAccount `ci-deploy`, whose image tag does not exist. The pod is
stuck and never becomes Ready.

Diagnose why using `kubectl describe pod/worker-app` and/or `kubectl get events`, then fix it
imperatively (delete and recreate the pod - for example with `kubectl run ... --dry-run=client -o yaml`
piped through an edit, or `kubectl replace --force -f -`) so that:

- The pod is still named `worker-app`, its container still named `worker-app`, still running as
  ServiceAccount `ci-deploy`, in namespace `q101-45-fix-imagepullbackoff-wrong-tag`.
- The image is corrected to the valid tag `nginx:1.25-alpine`.
- The pod reaches `Running` and `Ready`.

## Hint

Search kubernetes.io/docs for **"troubleshoot applications imagepullbackoff"** - the "Debug Running
Pods" task page and `kubectl describe pod` output both explain how an `ImagePullBackOff` /
`ErrImagePull` status traces back to the exact image reference the kubelet failed to pull.
