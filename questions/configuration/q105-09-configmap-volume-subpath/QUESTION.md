# q105-09: Mount a single ConfigMap key as one file without replacing a directory

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-09-configmap-volume-subpath`

A ConfigMap named `site-config` already exists with a key `index.html` (containing a small HTML
snippet), plus a running Pod named `landing-page` (image `nginx:1.25-alpine`) that already has an
**existing, unrelated file** at `/usr/share/nginx/html/existing-notice.txt`, in namespace
`q105-09-configmap-volume-subpath`.

Edit the pod so its container mounts **only** the `index.html` key from `site-config` as a single
file at `/usr/share/nginx/html/index.html`, without hiding or replacing any of the other existing
files already in `/usr/share/nginx/html`. The pod will need to be recreated for the mount to take
effect.

Verify with `kubectl exec landing-page -- ls /usr/share/nginx/html` - both `index.html` and
`existing-notice.txt` should be present.

## Hint

Search kubernetes.io/docs for **"configmap subPath"** - the Configure a Pod to Use a ConfigMap
task explains using `subPath` to mount a single key without overwriting the rest of the
directory.
