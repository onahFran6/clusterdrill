# q101-08: Update a Deployment's image with `kubectl set image`

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-08-set-image-deployment`

`setup.sh` already created a Deployment named `image-rollout` in namespace
`q101-08-set-image-deployment`, with a single container named `app` running `nginx:1.24-alpine`.

Using a single imperative `kubectl` command, update the `app` container's image to
`nginx:1.25-alpine` without editing the Deployment's YAML directly.

## Hint

Search kubernetes.io/docs for **"kubectl set image deployment"** - the `kubectl set image`
command reference shows how to update a running Deployment's container image imperatively and
trigger a rollout.
