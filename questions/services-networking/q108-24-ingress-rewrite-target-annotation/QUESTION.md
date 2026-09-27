# q108-24: Add a path-rewrite annotation so a stripped-prefix Ingress route works

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-24-ingress-rewrite-target-annotation`

A Deployment and Service (`shop-api`, Service `shop-api-svc` on port `80`)
already exist. The container only serves content at `/` and returns 404 for requests under
`/api/...`. An Ingress named `shop-ingress` (IngressClass `nginx`) routes path `/api`
(`pathType: Prefix`) to Service `shop-api-svc` port `80`, but those requests still 404 at the
backend.

Fix `shop-ingress` so the `/api` prefix is stripped before the request reaches the backend:

- Add the annotation `nginx.ingress.kubernetes.io/rewrite-target: /` to the Ingress's metadata.
- Change the rule's `path` to `/api(/|$)(.*)`.
- Change the rule's `pathType` to `ImplementationSpecific`.
- Leave the backend service and port (`shop-api-svc` port `80`) unchanged.

## Hint

Search kubernetes.io/docs for **"ingress-nginx rewrite"** - the "Rewrite" example under the
Ingress-Nginx Controller's annotations documentation shows
`nginx.ingress.kubernetes.io/rewrite-target` paired with a `(/|$)(.*)` capture-group path.
ingress-nginx's admission webhook rejects a regex path like `/api(/|$)(.*)` under
`pathType: Prefix`, which is why the rule needs `pathType: ImplementationSpecific`.
