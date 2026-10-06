# q113-11: One host, two apps by path

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-11-ingress-path-routing`

Team Capella serves two apps under one hostname. Services `shop-svc` and `api-svc` (both port
80) already exist.

- Create Ingress `capella` (class `nginx`) for a single host of your choice: `/shop` and
  everything under it routes to `shop-svc:80`, and `/api` and everything under it routes to
  `api-svc:80`.

This cluster has no Ingress controller installed, so grading checks the Ingress object's fields
only, not a live HTTP response through a controller.

## Hint

Search kubernetes.io/docs for **"kubectl create ingress"** - the command's own `--rule` flag
takes `"host/path=service:port"`, and a trailing `*` on the path means `Prefix`.
