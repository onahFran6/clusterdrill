# q102-07: Localhost networking between containers

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-07-localhost-networking-multi-container`

Create a Pod named `web-with-healthcheck` in this namespace with two
containers:

- `web` (image `nginx:1.27-alpine`) exposing container port `80`.
- `healthchecker` (image `busybox:1.36`) that repeatedly checks the `web`
  container is responding, by looping a request against
  `http://localhost:80` (or `127.0.0.1:80`) every few seconds, e.g.
  `sh -c "while true; do wget -q -O- http://localhost:80 || true; sleep 5; done"`.

You do **not** need to create a Service, a shared volume, or any DNS record
for `healthchecker` to reach `web` - containers in the same Pod share a
single network namespace, so `localhost` already routes between them.

## Hint

Search kubernetes.io/docs for **"pods share network namespace localhost"** -
the Pods concept page's "Containers in a Pod" section explains that
containers in the same Pod can reach each other's ports via `localhost`.
