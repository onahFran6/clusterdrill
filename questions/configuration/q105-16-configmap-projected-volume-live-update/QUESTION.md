# q105-16: Update a mounted ConfigMap without restarting the pod

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-16-configmap-projected-volume-live-update`

A ConfigMap named `banner-config` already exists with a key `banner.txt` containing
`v1-original`, and a running Pod named `banner-app` (image `nginx:1.25-alpine`) mounts
`banner-config` as a projected volume at `/etc/banner`, in namespace
`q105-16-configmap-projected-volume-live-update`.

Update the `banner.txt` key in `banner-config` to contain `v2-updated` instead. Do **not**
delete or recreate the pod, and do not change the file from inside the container by hand - the
already-running container should pick up the new content at `/etc/banner/banner.txt` within about
a minute.

Verify with `kubectl exec banner-app -- cat /etc/banner/banner.txt` - it should show `v2-updated`.

## Hint

Search kubernetes.io/docs for **"projected volume"** - the Projected Volumes concept page (and
the ConfigMaps page's note on mounted ConfigMaps being updated automatically) explains that
kubelet periodically resyncs the volume's contents without requiring a pod restart.
