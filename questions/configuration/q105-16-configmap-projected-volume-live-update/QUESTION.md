# q105-16: Update a mounted ConfigMap without restarting the pod

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-16-configmap-projected-volume-live-update`

`setup.sh` already created a ConfigMap named `banner-config` with a key `banner.txt` containing
`v1-original`, and a running pod named `banner-app` (image `nginx:1.25-alpine`) that mounts
`banner-config` as a **projected volume** at `/etc/banner`, in namespace
`q105-16-configmap-projected-volume-live-update`.

Update the `banner.txt` key in `banner-config` to contain `v2-updated` instead - using **only** a
ConfigMap update (`kubectl edit`, `kubectl apply`, `kubectl patch`, etc.). Do **not** delete or
recreate the pod, and do not `kubectl exec` into the container to change the file by hand: rely
on the kubelet's automatic projected-volume refresh to propagate the new content into the
already-running container within about a minute.

## Hint

Search kubernetes.io/docs for **"projected volume"** - the Projected Volumes concept page (and
the ConfigMaps page's note on mounted ConfigMaps being updated automatically) explains that
kubelet periodically resyncs the volume's contents without requiring a pod restart.
