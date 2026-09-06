# q105-45-configmap-subpath-no-live-update: Roll out a ConfigMap change that subPath won't auto-refresh

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-45-configmap-subpath-no-live-update`

`setup.sh` already created a ConfigMap named `app-version` with a key `version.txt` containing
`v1.0.0`, and a running pod named `version-display` (image `nginx:1.25-alpine`) that mounts that
key as a single file via `subPath` at `/usr/share/nginx/html/version.txt`, in namespace
`q105-45-configmap-subpath-no-live-update`.

Update `version.txt` in `app-version` to `v2.0.0`, and get the pod's mounted file to actually show
`v2.0.0`.

Editing the ConfigMap alone is **not** enough here: kubelet's periodic resync that refreshes a
mounted ConfigMap's content in-place only works for whole-directory volume mounts - a key mounted
via `subPath` is copied in once at container start and is never refreshed afterwards, no matter
how long you wait. To pick up the new value, the pod's container has to actually be recreated
(for example `kubectl delete pod version-display` followed by re-applying its manifest, or an
equivalent that starts a fresh container) after the ConfigMap is updated.

## Hint

Search kubernetes.io/docs for **"configmap subPath"** - the Configure a Pod to Use a ConfigMap
task's note on `subPath` explains that a ConfigMap update is **not** propagated to volumes
mounted using `subPath`.

