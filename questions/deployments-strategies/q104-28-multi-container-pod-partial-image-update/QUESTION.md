# q104-28: Update one container's image in a multi-container Deployment

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-28-multi-container-pod-partial-image-update`

A Deployment named `edge-proxy` already exists in namespace
`q104-28-multi-container-pod-partial-image-update` with 2 replicas and two containers per pod:

- `proxy` (image `nginx:1.25-alpine`)
- `sidecar-agent` (image `busybox:1.36`)

Update only the `sidecar-agent` container's image to `busybox:1.36.1`. Leave `proxy` on
`nginx:1.25-alpine`, and confirm the Deployment reaches 2 ready replicas again.

## Hint

Search kubernetes.io/docs for **"kubectl set image"** - the reference page shows the
`deployment/name container=image` syntax, which targets one named container in a
multi-container pod template without touching the others.
