# q108-51: Add an allow-all NetworkPolicy alongside an existing deny-all

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-51-networkpolicy-additive-allow-overrides-deny`

A Deployment named `api` (pod-template label `app=api`) already exists in namespace
`q108-51-networkpolicy-additive-allow-overrides-deny`, along with a NetworkPolicy named
`api-deny-all-ingress` that selects `app=api` pods and denies all ingress traffic to them
(`policyTypes: [Ingress]`, no `ingress` rules).

Leave `api-deny-all-ingress` exactly as it is. Create a **second** NetworkPolicy named
`api-allow-all-ingress` in the same namespace that:

- selects pods with `podSelector.matchLabels.app: api`
- sets `policyTypes: [Ingress]`
- defines exactly one ingress rule with no restrictions: an empty `{}` entry under `ingress`

Once both policies exist, ingress traffic to `api`'s pods must be allowed.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the concept page states that
NetworkPolicies are additive. A pod's effective policy is the union of every NetworkPolicy that
selects it, and any single policy that permits a connection allows it. An example of "allow every
source and port" is `ingress: - {}`. The existing deny policy does not subtract from what the
new policy grants.
