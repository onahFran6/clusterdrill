# q104-35-basic-image-update-set-image: Update a Deployment's image with kubectl set image

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-35-basic-image-update-set-image`

`setup.sh` already created a Deployment named `web-cache` (container name `web-cache`, image
`redis:7.2-alpine`, 3 replicas) in namespace `q104-35-basic-image-update-set-image`, and it is
already fully rolled out with all 3 replicas Ready.

Update `web-cache`'s image to `redis:7.4-alpine` using `kubectl set image`, and wait until the
rollout finishes with all 3 replicas Ready on the new image.

## Hint

Search kubernetes.io/docs for **"kubectl set image"** - the `kubectl set image` command reference
shows the `deployment/<name> <container>=<image>` syntax for updating a container's image without
editing the whole manifest.
