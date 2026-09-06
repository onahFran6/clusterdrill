# q108-24-ingress-rewrite-target-annotation: Add a path-rewrite annotation so a stripped-prefix Ingress route works

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-24-ingress-rewrite-target-annotation`

`setup.sh` already created a Deployment/Service (`shop-api`, Service `shop-api-svc` on port `80`)
whose container only serves content at `/` - it returns a 404 for any request under `/api/...`.
It also created an Ingress named `shop-ingress` (IngressClass `nginx`) that routes path `/api`
(`pathType: Prefix`) to Service `shop-api-svc` port `80`, but requests to `/api/anything` still
404 at the backend because the backend has no idea about the `/api` prefix.

Fix `shop-ingress` so the `/api` prefix is stripped before the request reaches the backend:

- Add the annotation `nginx.ingress.kubernetes.io/rewrite-target: /` to the Ingress's metadata.
- Change the rule's `path` to the capture-group form `/api(/|$)(.*)` so ingress-nginx's
  rewrite-target annotation has a capture group to rewrite into.
- Change the rule's `pathType` to `ImplementationSpecific` - ingress-nginx's admission webhook
  rejects a regex path like `/api(/|$)(.*)` under `pathType: Prefix`.
- Leave the backend service/port (`shop-api-svc` port `80`) unchanged.

## Hint

Search kubernetes.io/docs for **"ingress-nginx rewrite"** - the "Rewrite" example under the
Ingress-Nginx Controller's annotations documentation shows the exact
`nginx.ingress.kubernetes.io/rewrite-target` annotation paired with a `(/|$)(.*)` capture-group
path.
