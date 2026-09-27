# q102-15: Sidecar file puller

**Domain:** Application Design and Build · **Points:** 7 · **Namespace:** `q102-15-sidecar-file-puller`

Create a Pod named `content-server` in this namespace with two containers that
share a single `emptyDir` volume named `web-content`:

- `content-puller` (image `busybox:1.36`) - periodically (re)writes
  `/www/index.html` with placeholder HTML, for example:
  `sh -c "while true; do echo '<html>synced content</html>' > /www/index.html; sleep 30; done"`.
  Mount `web-content` at `/www`.
- `web` (image `nginx:1.27-alpine`) - serves whatever `content-puller` writes.
  Mount the same `web-content` volume at `/usr/share/nginx/html` (nginx's
  default document root).

The Pod must end up with exactly two containers: `content-puller` and `web`,
both mounting `web-content`, with `web` mounting it at `/usr/share/nginx/html`.

## Hint

Search kubernetes.io/docs for **"multi-container pods communicate"** - the
Pods concept page's "Communication between containers in the same Pod"
section shows the shared-volume pattern this task is based on.
