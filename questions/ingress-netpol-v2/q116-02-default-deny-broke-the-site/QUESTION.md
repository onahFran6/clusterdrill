# q116-02: Default deny broke the website

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-02-default-deny-broke-the-site`

This namespace runs `site` (Deployment + Service `site-svc`, a `hashicorp/http-echo` instance
listening on container port `5678`, exposed through Service port `80`) and an Ingress `nova`
(host `nova.local`) routing to `site-svc`. A `default-deny` NetworkPolicy
(`podSelector: {}`, `policyTypes: [Ingress]`, no rules) was applied to this namespace, and it also
runs an unrelated pod, `neighbour`.

- Create NetworkPolicy `allow-ingress-controller` so the `site` pods accept traffic **only** from
  the ingress-nginx controller pods, and only on the port the app's container actually listens on.
  Leave `default-deny` in place - don't delete or edit it.
- (ungraded, Task narrative only) Note the HTTP status through the Ingress before and after your
  fix, and the result of requesting `site-svc` directly from the `neighbour` pod.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy"** - the concept page's own example shows a
`podSelector` combined with an `ingress[].from` list that itself contains a `namespaceSelector`
and `podSelector` pair. Where do the packets that reach a `site` pod actually come from: the
Service, or the controller pods? Which port do they land on - the Service's port, or the
container's own listening port?
