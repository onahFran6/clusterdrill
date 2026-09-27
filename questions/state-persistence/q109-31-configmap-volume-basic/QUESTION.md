# q109-31-configmap-volume-basic: Mount a ConfigMap as a volume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-31-configmap-volume-basic`

A ConfigMap named `app-settings` already exists in namespace `q109-31-configmap-volume-basic`
with two keys, `mode` (value `production`) and `retries` (value `3`).

Create a Pod named `settings-reader` (image `busybox:1.36`, command
`["sh", "-c", "sleep 3600"]`) that mounts `app-settings` as a volume at `/etc/app-settings`,
so each key becomes a file at `/etc/app-settings/mode` and `/etc/app-settings/retries`.

## Hint

Search kubernetes.io/docs for **"ConfigMap" "populate a volume"** - the ConfigMaps concept
page's "Populate a Volume with data stored in a ConfigMap" section shows the
`spec.volumes[].configMap.name` and matching `volumeMounts[].mountPath` fields used to
project every key in a ConfigMap as a file. Mount the ConfigMap as a volume, not as individual
environment variables.
