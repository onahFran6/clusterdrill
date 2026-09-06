# q108-28-diagnose-dns-wrong-namespace-suffix: Diagnose and fix a hardcoded cross-namespace DNS suffix breaking a client Deployment

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-28-diagnose-dns-wrong-namespace-suffix`

`setup.sh` already created two namespaces:

- `q108-28-diagnose-dns-wrong-namespace-suffix-backend`, containing a Deployment `orders-api` and a
  Service `orders-svc` (port `8080`) that is actually serving traffic.
- `q108-28-diagnose-dns-wrong-namespace-suffix-frontend`, containing a Deployment `web-ui` whose
  container repeatedly curls an env var `ORDERS_URL` in a loop and writes the result to a file used
  by its liveness probe.

`web-ui`'s pods are stuck `CrashLoopBackOff` (failing liveness). Its container's `ORDERS_URL` env
var is hardcoded to
`http://orders-svc.q108-28-diagnose-dns-wrong-namespace-suffix-backend-old.svc.cluster.local:8080/`
- a namespace suffix (`-backend-old`) that does not exist. The real backend namespace is
`q108-28-diagnose-dns-wrong-namespace-suffix-backend`.

Edit the `web-ui` Deployment in the `-frontend` namespace so its `ORDERS_URL` env var points at the
correct namespace (`q108-28-diagnose-dns-wrong-namespace-suffix-backend`), then confirm `web-ui`'s
pods become `Ready 1/1`.

## Hint

Search kubernetes.io/docs for **"DNS for Services and Pods"** - the DNS concept page's "What
things get DNS names" section spells out the full
`<service>.<namespace>.svc.cluster.local` form; a Pod resolving a Service in another namespace must
name that namespace exactly, or the lookup returns NXDOMAIN and any client that treats that as fatal
never becomes healthy.
