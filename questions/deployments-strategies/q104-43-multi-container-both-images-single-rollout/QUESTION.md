# q104-43-multi-container-both-images-single-rollout: Update two containers' images in one rollout event

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-43-multi-container-both-images-single-rollout`

`setup.sh` already created a Deployment named `edge-proxy` (2 replicas) in namespace
`q104-43-multi-container-both-images-single-rollout` with two containers:

- `proxy` - image `nginx:1.24-alpine`
- `sidecar-logger` - image `busybox:1.35`, command `sleep 3600`

It is already fully rolled out with both replicas Ready.

Update **both** containers' images - `proxy` to `nginx:1.25-alpine` and `sidecar-logger` to
`busybox:1.36` - as a single combined change (one `kubectl patch` or `kubectl apply`, not two
separate `kubectl set image` calls), so only **one** new revision is created for both changes
together. Wait until both replicas are Ready again with both new images.

## Hint

Search kubernetes.io/docs for **"kubectl set image multiple containers"** - the `kubectl set
image` reference shows that a single invocation can take multiple `container=image` pairs, which
produces one pod template change (and one new ReplicaSet revision) instead of one per container.
