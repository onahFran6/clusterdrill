# q116-07: Longest prefix wins

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-07-longest-prefix-wins`

Services `v1-svc` and `v2-svc` (both port `80`) already exist, with their matching Deployments.
This team is migrating its API to v2 one path at a time.

- Create Ingress `zenith` (class `nginx`, host `zenith.local`): `/api` and everything below it
  routes to `v1-svc`, and `/api/v2` and everything below it routes to `v2-svc`. Set no default
  backend.
- (ungraded, Task narrative only) Predict, then write, the result for `/api/users`,
  `/api/v2/users`, `/api/v2x` and `/apix`.

## Hint

Search kubernetes.io/docs for **"Ingress"** - when several `Prefix` paths match the same request,
which one does the spec say wins? Does the order you list the rules in matter? Remember `Prefix`
compares whole URL path elements split on `/`, so `/api/v2x` is not actually under `/api/v2`.
