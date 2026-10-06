# q116-15: Three tiers, locked both ways

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-15-three-tiers-locked-both-ways`

This namespace runs three tiers, each a pod + Service: `web` (label `tier: web`, container port
`8080`), `api` (label `tier: api`, container port `8080`), and `db` (label `tier: db`, container
port `5432`). Ingress `cartwheel` publishes `web-svc`. Two NetworkPolicies already exist and must
stay as they are: `deny-all` (all ingress and egress, every pod) and `allow-dns` (every pod may
query cluster DNS).

- Allow exactly this chain, and nothing more: the ingress-nginx controller to `web` on its
  container port; `web` to `api` on its container port; `api` to `db` on TCP `5432`. Every hop
  needs both an egress allowance on the sender and an ingress allowance on the receiver where
  applicable - create one NetworkPolicy per tier (`web`, `api`, `db`), each holding both halves of
  the chain that tier participates in.
- (ungraded, Task narrative only) Record the five-pair connectivity matrix: controller→web,
  web→api, api→db, web→db, and db→api.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy"** - draw the chain, and for each arrow write two
lines: egress on the sender, ingress on the receiver. The controller is outside this namespace, so
`web`'s ingress rule needs a namespace selector too.
