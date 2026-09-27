# q105-43-configmap-binarydata-from-file: Mount a ConfigMap built from non-text binary content

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-43-configmap-binarydata-from-file`

A small non-UTF-8 binary file already exists at `~/assets/logo.bin`, plus a running Pod named
`asset-server` (image `nginx:1.25-alpine`) with no volumes yet, in namespace
`q105-43-configmap-binarydata-from-file`. No ConfigMap exists yet.

Create a ConfigMap named `app-assets` from `~/assets/logo.bin` with `kubectl create configmap
--from-file`. Then edit the pod so its container mounts `app-assets` as a volume at
`/etc/assets`, and confirm the file lands there with its bytes byte-for-byte intact. The pod will
need to be recreated for the mount to take effect.

## Hint

Search kubernetes.io/docs for **"configmap binarydata"** - the ConfigMap concept page's
`binaryData` field description explains that `kubectl create configmap --from-file` automatically
routes non-UTF-8 file content there instead of into `data`.
