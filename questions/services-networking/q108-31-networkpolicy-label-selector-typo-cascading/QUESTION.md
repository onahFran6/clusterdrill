# q108-31: Fix a NetworkPolicy selector that never matches the allowed client

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-31-networkpolicy-label-selector-typo-cascading`

Two Deployments already exist in namespace
`q108-31-networkpolicy-label-selector-typo-cascading`:

- `cache-layer` (pod-template label `tier: cache`, container port `6379`) - the service to protect
- `api-layer` (pod-template label `tier: api`) - the only client that should be allowed to reach it

Two NetworkPolicies both select `cache-layer`'s pods (`podSelector` matching `tier=cache`):

- `default-deny-cache-ingress` - sets `policyTypes: [Ingress]` with no `ingress` rules, denying
  every inbound connection by default
- `allow-api-to-cache` - meant to allow ingress from pods labeled `tier: api` on TCP port `6379`,
  but that allow rule does not match `api-layer`

Fix `allow-api-to-cache` so its ingress `podSelector.matchLabels` is `tier: api`, without changing
anything else in that policy and without touching `default-deny-cache-ingress`. Once fixed,
`api-layer` pods must be able to reach `cache-layer` pods on port `6379`, while pods carrying any
other label stay denied.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the NetworkPolicy concept page
explains that policies selecting the same pods are additive: a connection is allowed if any
matching policy's ingress rule allows it. Compare `allow-api-to-cache`'s `matchLabels` with
`api-layer`'s real labels. A value that matches nothing leaves the empty deny rule as the only
one in effect.
