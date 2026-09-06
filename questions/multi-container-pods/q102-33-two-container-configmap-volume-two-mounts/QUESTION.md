# q102-33-two-container-configmap-volume-two-mounts: One ConfigMap, two containers, two mount paths

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-33-two-container-configmap-volume-two-mounts`

A ConfigMap named `shared-settings` already exists in this namespace with a
key `mode.conf` (content `region=eu-west-1`).

Create a Pod named `settings-readers` with two containers, both reading the
**same** ConfigMap as a volume, mounted at **different** paths:

- `primary` (image `busybox:1.36`) - mounts the `shared-settings` ConfigMap
  as a volume named `settings` at `/etc/primary-settings`, then idles.
- `secondary` (image `busybox:1.36`) - mounts the **same** ConfigMap as a
  volume also named `settings`, but at `/etc/secondary-settings`, then
  idles.

Both containers must be able to read `mode.conf` at their own mount path
(`/etc/primary-settings/mode.conf` for `primary`,
`/etc/secondary-settings/mode.conf` for `secondary`), and both must see the
exact same content, since they mount the same ConfigMap.

## Hint

Search kubernetes.io/docs for **"ConfigMap"** - the ConfigMaps concept
page's "Using ConfigMaps" section shows how a Pod's `volumes[].configMap`
plus each container's own `volumeMounts` mounts the same ConfigMap at as
many different paths as the Pod needs.
