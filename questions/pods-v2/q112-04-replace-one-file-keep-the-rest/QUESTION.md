# q112-04: Replace one file, keep the rest

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-04-replace-one-file-keep-the-rest`

ConfigMap `site` (keys `index.html` and `health.html`) is already seeded here. A stock nginx Pod
needs to serve both of those files without losing nginx's own default files.

- Create Pod `web` (`nginx:1.27`). `index.html` from the ConfigMap must replace
  `/usr/share/nginx/html/index.html`, and `health.html` must appear as
  `/usr/share/nginx/html/healthz`.
- nginx's own default `50x.html` must still exist in that same directory afterward - this is the
  actual point of the task.

## Hint

Search kubernetes.io/docs for **"subPath"** in the Volumes concept page. Mounting a volume
directly on `/usr/share/nginx/html` would hide everything the image already has there, including
`50x.html`. Which `volumeMounts` field places a single ConfigMap key as a single file instead of
replacing a whole directory? The same ConfigMap volume can be mounted more than once with
different `subPath`/`mountPath` pairs.
