# q105-41-configmap-volume-selected-items-rename: Mount only two of a ConfigMap's three keys, renamed

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-41-configmap-volume-selected-items-rename`

A ConfigMap named `site-config` already exists with three keys in namespace
`q105-41-configmap-volume-selected-items-rename`:

- `header.html` containing `<h1>Header</h1>`
- `footer.html` containing `<footer>Footer</footer>`
- `internal-notes.txt` containing `DO-NOT-SHIP`

...and a running Pod named `site-renderer` (image `nginx:1.25-alpine`) with no volumes yet.

Edit the pod so its container mounts a ConfigMap volume at `/etc/site` containing **only**
`header.html` and `footer.html`, renamed on disk to `/etc/site/head.html` and
`/etc/site/foot.html` respectively. The `internal-notes.txt` key must not appear anywhere under
`/etc/site`, and neither should a file still named `header.html` or `footer.html` - only the
renamed `head.html`/`foot.html`. The pod will need to be recreated for the change to take effect.

## Hint

Search kubernetes.io/docs for **"configure a pod to use a configmap"** - the "Add ConfigMap data
to a specific path in the Volume" section shows the volume's `items` list, where each entry's
`key` selects one ConfigMap key and `path` sets the mounted filename, letting you both filter and
rename in one step.
