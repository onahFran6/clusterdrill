# q108-10: Route two paths to two Services with one Ingress

**Domain:** Services and Networking · **Points:** 7 · **Namespace:** `q108-10-ingress-path-based-routing`

`setup.sh` already created two Deployments and their matching ClusterIP Services in namespace
`q108-10-ingress-path-based-routing`:

- `catalog` (Service `catalog-svc`, port `80`)
- `checkout` (Service `checkout-svc`, port `80`)

Create an Ingress named `shop-ingress` in this namespace, using IngressClass `nginx`, that routes:

- requests under path `/catalog` to Service `catalog-svc` port `80`
- requests under path `/checkout` to Service `checkout-svc` port `80`

Use `pathType: Prefix` for both rules so that sub-paths (e.g. `/catalog/items`) also match.

## Hint

Search kubernetes.io/docs for **"Ingress"** - the Ingress concept page's "Simple fanout" example
shows exactly this shape: one Ingress, one host-less set of rules, multiple `path` entries each
pointing at a different `backend.service.name`.
