# q108-28: Fix a client Deployment whose cross-namespace DNS name does not resolve

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-28-diagnose-dns-wrong-namespace-suffix`

Two namespaces already exist:

- `q108-28-diagnose-dns-wrong-namespace-suffix-backend`, containing a Deployment `orders-api` and a
  Service `orders-svc` (port `8080`) that is serving traffic.
- `q108-28-diagnose-dns-wrong-namespace-suffix-frontend`, containing a Deployment `web-ui` whose
  container repeatedly requests an env var `ORDERS_URL` and writes the result to a file used by
  its liveness probe.

`web-ui`'s pods are stuck `CrashLoopBackOff`. `ORDERS_URL` is a cluster DNS name that does not
resolve.

Edit the `web-ui` Deployment in the `-frontend` namespace so `ORDERS_URL` is exactly
`http://orders-svc.q108-28-diagnose-dns-wrong-namespace-suffix-backend.svc.cluster.local:8080/`,
then confirm `web-ui`'s pods become `Ready 1/1`.

## Hint

Search kubernetes.io/docs for **"DNS for Services and Pods"** - the DNS concept page's "What
things get DNS names" section spells out `<service>.<namespace>.svc.cluster.local`. A namespace
suffix that does not exist returns NXDOMAIN, and a client that treats that failure as fatal never
becomes healthy. Compare `ORDERS_URL` with the backend namespace that actually exists.
