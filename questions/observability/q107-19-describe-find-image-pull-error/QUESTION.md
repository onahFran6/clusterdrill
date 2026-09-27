# q107-19: Diagnose and fix a pod stuck in ImagePullBackOff

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-19-describe-find-image-pull-error`

A pod named `catalog-api` already exists in namespace `q107-19-describe-find-image-pull-error`.
It never reaches `Running`. Its status is `ImagePullBackOff` or `ErrImagePull`.

Fix it:

- set the container image to `nginx:1.25-alpine`
- keep the pod named `catalog-api`, in the same namespace, with the same container name
- you may delete and recreate the pod with the same name and container name
- the pod must end up `Running` with its container ready

## Hint

Search kubernetes.io/docs for **"debug pods"** - the Troubleshooting Applications guide shows how
to read `kubectl describe pod` Events to diagnose `ImagePullBackOff`/`ErrImagePull` failures.
The Events name a `Failed to pull image` error for an image tag that does not exist. The current
tag is a typo of `nginx:1.25-alpine`.
