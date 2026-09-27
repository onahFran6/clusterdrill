# q108-13: Catch unmatched requests with an Ingress default backend

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-13-ingress-default-backend`

Two Deployments with matching ClusterIP Services already exist in namespace
`q108-13-ingress-default-backend`:

- `docs-app` (Service `docs-svc`, port `80`) - the real application
- `fallback-app` (Service `fallback-svc`, port `80`) - a "not found" page for anything else

Create an Ingress named `docs-ingress` in this namespace, using IngressClass `nginx`, that:

- routes path `/docs` (`pathType: Prefix`) to `docs-svc` port `80`
- sets `fallback-svc` port `80` as the Ingress's **default backend**, so any request that does not
  match `/docs` (or any other rule) is served by that Service

## Hint

Search kubernetes.io/docs for **"Ingress default backend"** - the Ingress concept page's Default
backend section shows the `spec.defaultBackend.service` field, separate from `spec.rules`.
Requests that match no rule use that backend instead of a generic controller 404.
