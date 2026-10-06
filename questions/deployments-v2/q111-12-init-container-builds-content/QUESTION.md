# q111-12: Init container builds the content

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-12-init-container-builds-content`

Team Vesta's `docs` Deployment (seeded, 2 replicas, stock `nginx:1.27`) serves the default nginx
page. They want each pod to generate its own page before nginx starts.

- Add an init container named `build` using `busybox:1.36` that writes the text
  `built by init on <pod hostname>` into an `index.html`.
- nginx must serve that file at `/`. Use a volume that lives only as long as the pod.

## Hint

Search kubernetes.io/docs for **"Init Containers"**. Which built-in volume type is created with
the pod and deleted with it? Both containers need to mount it, but at different paths - where
does nginx actually look for pages by default? The init container needs a shell to expand
`$(hostname)`.
