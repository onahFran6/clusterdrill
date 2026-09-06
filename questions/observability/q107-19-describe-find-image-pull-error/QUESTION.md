# q107-19: Diagnose and fix a pod stuck in ImagePullBackOff

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-19-describe-find-image-pull-error`

`setup.sh` already created a pod named `catalog-api` in namespace
`q107-19-describe-find-image-pull-error`. The pod is stuck and never reaches `Running` -
`kubectl get pod catalog-api -n q107-19-describe-find-image-pull-error` shows
`Status: ImagePullBackOff` (or `ErrImagePull`).

Investigate the pod to find the root cause, then fix it:

- Run `kubectl describe pod catalog-api -n q107-19-describe-find-image-pull-error` and read the
  `Events` section - it reports a `Failed to pull image` error naming the exact image tag that
  could not be found.
- The container's image tag has a typo. Edit the pod so its container uses the correct image
  `nginx:1.25-alpine` instead.
- Keep the pod named `catalog-api`, keep it in namespace
  `q107-19-describe-find-image-pull-error`, and keep the container name unchanged. You may delete
  and recreate the pod with the same name/container name to fix the image.

The pod must end up `Running` with its container ready.

## Hint

Search kubernetes.io/docs for **"debug pods"** - the Troubleshooting Applications guide shows how
to read `kubectl describe pod` Events to diagnose `ImagePullBackOff`/`ErrImagePull` failures.
