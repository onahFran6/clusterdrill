# q104-43: Update both containers' images in one revision

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-43-multi-container-both-images-single-rollout`

A Deployment named `edge-proxy` (2 replicas) already exists in namespace
`q104-43-multi-container-both-images-single-rollout` with two containers, fully rolled out and
Ready:

- `proxy` - image `nginx:1.24-alpine`
- `sidecar-logger` - image `busybox:1.35`, command `sleep 3600`

Update both images - `proxy` to `nginx:1.25-alpine` and `sidecar-logger` to `busybox:1.36` - as
one combined change so only one new rollout revision is created. Wait until both replicas are
Ready again with both new images.

## Hint

Search kubernetes.io/docs for **"kubectl set image multiple containers"** - a single
`kubectl set image` (or one `kubectl patch` / `kubectl apply`) can take multiple
`container=image` pairs. That produces one pod-template change and one new ReplicaSet revision,
unlike two separate updates which would create two revisions.
