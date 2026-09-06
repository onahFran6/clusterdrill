# q108-13: Catch unmatched requests with an Ingress default backend

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-13-ingress-default-backend`

`setup.sh` already created two Deployments with matching ClusterIP Services in namespace
`q108-13-ingress-default-backend`:

- `docs-app` (Service `docs-svc`, port `80`) - the real application
- `fallback-app` (Service `fallback-svc`, port `80`) - a "not found" style page for anything else

Create an Ingress named `docs-ingress` in this namespace, using IngressClass `nginx`, that:

- routes path `/docs` (`pathType: Prefix`) to `docs-svc` port `80`
- sets `fallback-svc` port `80` as the Ingress's **default backend**, so any request that doesn't
  match `/docs` (or any other rule) falls through to it instead of returning a generic 404 from
  the controller itself

## Hint

Search kubernetes.io/docs for **"Ingress default backend"** - the Ingress concept page's Default
backend section shows the `spec.defaultBackend.service` field, separate from `spec.rules`.
