# q105-43-configmap-binarydata-from-file: Mount a ConfigMap built from non-text binary content

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-43-configmap-binarydata-from-file`

`setup.sh` already wrote a small non-UTF-8 binary file to `~/assets/logo.bin`, and created a
running pod named `asset-server` (image `nginx:1.25-alpine`) with no volumes yet, in namespace
`q105-43-configmap-binarydata-from-file`. No ConfigMap exists yet.

Create a ConfigMap named `app-assets` from `~/assets/logo.bin` with `kubectl create configmap
--from-file`. Because the file's bytes are not valid UTF-8 text, `kubectl` stores them under the
ConfigMap's `binaryData` field (base64-encoded) rather than under `data` - this is automatic, you
do not choose it. Then edit the pod so its container mounts `app-assets` as a volume at
`/etc/assets`, and confirm the file lands there with its bytes byte-for-byte intact. The pod will
need to be recreated for the mount to take effect.

## Hint

Search kubernetes.io/docs for **"configmap binarydata"** - the ConfigMap concept page's
`binaryData` field description explains that `kubectl create configmap --from-file` automatically
routes non-UTF-8 file content there instead of into `data`.
