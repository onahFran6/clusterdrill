# q116-19: Neighbours and the ingress only

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-19-neighbours-and-the-ingress-only`
(plus a second namespace, `q116-19-neighbours-and-the-ingress-only-stranger`)

Pod `shop` (label `app: shop`, with its matching Service `shop-svc`) is published at
`fornax.local` through Ingress `fornax`. Pod `neighbour` also runs in this namespace. Pod
`stranger` runs in the other namespace. `shop` must accept traffic from any pod in its own
namespace **and** from the ingress-nginx controller, but from **no other namespace**.

- Create NetworkPolicy `shop-sources` doing exactly that, in **one** policy.
- (ungraded, Task narrative only) Record the results for `neighbour`, `stranger`, and the
  Ingress.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy"** - two independent sources means two entries in
one `from` list. Which bare selector on its own means "every pod in this policy's own namespace"?
Which pair of selectors in one `from` entry means "these specific pods, in that other
namespace"?
