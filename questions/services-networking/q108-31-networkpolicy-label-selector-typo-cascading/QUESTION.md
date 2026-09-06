# q108-31-networkpolicy-label-selector-typo-cascading: Resolve two interacting NetworkPolicies where a pod-label typo silently isolates a Deployment

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-31-networkpolicy-label-selector-typo-cascading`

`setup.sh` already created two Deployments in namespace
`q108-31-networkpolicy-label-selector-typo-cascading`:

- `cache-layer` (pod-template label `tier: cache`, container port `6379`) - the service to protect
- `api-layer` (pod-template label `tier: api`) - the only client that should be allowed to reach it

It also created two NetworkPolicies that both select `cache-layer`'s pods (`podSelector: tier=cache`):

- `default-deny-cache-ingress` - an intentional baseline that sets `policyTypes: [Ingress]` with no
  `ingress` rules at all, denying every inbound connection by default
- `allow-api-to-cache` - meant to punch a hole in that baseline by allowing ingress from pods
  labeled `tier: api` on TCP port `6379`, but its `ingress[].from[].podSelector.matchLabels` was
  typed as `tier: ap` (missing the trailing `i`)

Because NetworkPolicies selecting the same pods are additive (a connection is allowed if *any*
matching policy's ingress rule allows it), the typo means no policy ever actually matches
`api-layer`'s real `tier: api` label, so `default-deny-cache-ingress`'s empty ingress list is the
only rule in effect and all traffic to `cache-layer` is denied - including from `api-layer`.

Fix `allow-api-to-cache` so it does what it was meant to do: correct its ingress rule's
`podSelector.matchLabels` from `tier: ap` to `tier: api`, without changing anything else in that
policy and without touching `default-deny-cache-ingress` at all (it is a deliberate baseline, not
the bug). Once fixed, `api-layer` pods must be able to reach `cache-layer` pods on port `6379`,
while pods carrying any other label continue to be denied.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the NetworkPolicy concept page
explains that when multiple policies select the same pods, the ingress/egress rules from all of
them are combined additively, so a single mistyped `podSelector` value in one policy can silently
leave a baseline deny rule as the only one that ever applies.
