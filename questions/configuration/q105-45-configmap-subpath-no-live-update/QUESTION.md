# q105-45-configmap-subpath-no-live-update: Roll out a ConfigMap change to a single-file mount

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-45-configmap-subpath-no-live-update`

A ConfigMap named `app-version` already exists with a key `version.txt` containing `v1.0.0`, and
a running Pod named `version-display` (image `nginx:1.25-alpine`) that mounts that key as a
single file at `/usr/share/nginx/html/version.txt`, in namespace
`q105-45-configmap-subpath-no-live-update`.

Update `version.txt` in `app-version` to `v2.0.0`, and get the pod's mounted file to actually show
`v2.0.0`. Editing the ConfigMap alone is **not** enough - the pod's container has to be recreated
after the ConfigMap is updated for the mounted file to pick up the new value.

## Hint

Search kubernetes.io/docs for **"configmap subPath"** - the Configure a Pod to Use a ConfigMap
task's note on `subPath` explains that a ConfigMap update is **not** propagated to volumes
mounted using `subPath`: the file is copied in once at container start and is never refreshed
afterwards, so the container must be recreated to pick up a new value.
