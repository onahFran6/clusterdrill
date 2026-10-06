# q116-03: Two teams, one hostname

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-03-two-teams-one-hostname`
(plus a second namespace, `q116-03-two-teams-one-hostname-blog`)

Two teams share the host `nebula.local`. Team Shop owns Service `shop-svc` (port `80`) in this
namespace. Team Blog owns Service `blog-svc` (port `80`) in
`q116-03-two-teams-one-hostname-blog`. Both are already running - don't create any Service.

- In this namespace, create Ingress `shop` (class `nginx`) routing `nebula.local/shop` (and
  everything below it) to `shop-svc` port `80`.
- In `q116-03-two-teams-one-hostname-blog`, create Ingress `blog` (class `nginx`) routing
  `nebula.local/blog` (and everything below it) to `blog-svc` port `80`.
- (ungraded, Task narrative only) Predict, then check, the responses for `/shop/cart` and
  `/blog/post`.

## Hint

Search kubernetes.io/docs for **"Ingress"** and look at the `backend.service` field: does it have
a `namespace` key? An Ingress can only route to Services that live in its own namespace, which is
why each team needs its own routing object, sharing just the host.
