# q108-11: Route two hostnames to two Services with one Ingress

**Domain:** Services and Networking · **Points:** 7 · **Namespace:** `q108-11-ingress-host-based-routing`

`setup.sh` already created two Deployments and their matching ClusterIP Services in namespace
`q108-11-ingress-host-based-routing`:

- `blog` (Service `blog-svc`, port `80`)
- `api` (Service `api-svc`, port `8080`)

Create an Ingress named `sites-ingress` in this namespace, using IngressClass `nginx`, that routes
based on the request's `Host` header rather than its path:

- host `blog.ckad.example.com` -> Service `blog-svc` port `80`
- host `api.ckad.example.com` -> Service `api-svc` port `8080`

Each host's rule should match all paths under it (path `/`, `pathType: Prefix`).

## Hint

Search kubernetes.io/docs for **"Ingress"** - the Ingress concept page's "Name based virtual
hosting" example shows multiple `rules[].host` entries in one Ingress, each with its own backend.
