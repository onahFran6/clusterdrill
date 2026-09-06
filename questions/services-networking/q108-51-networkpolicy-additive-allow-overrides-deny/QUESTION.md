# q108-51-networkpolicy-additive-allow-overrides-deny: Add an allow-all NetworkPolicy alongside an existing deny-all

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-51-networkpolicy-additive-allow-overrides-deny`

`setup.sh` already created a Deployment named `api` (pod-template label `app=api`) in namespace
`q108-51-networkpolicy-additive-allow-overrides-deny`, along with a NetworkPolicy named
`api-deny-all-ingress` that selects `app=api` pods and denies all ingress traffic to them
(`policyTypes: [Ingress]`, no `ingress` rules).

Leave `api-deny-all-ingress` exactly as it is - do not delete or edit it. Create a **second**
NetworkPolicy named `api-allow-all-ingress` in the same namespace that:

- selects pods with `podSelector.matchLabels.app: api` (the same pods the deny-all policy already
  selects)
- sets `policyTypes: [Ingress]`
- defines exactly one ingress rule with no restrictions at all - an empty `{}` entry under
  `ingress`, meaning "allow traffic from any source, on any port"

Once both policies exist, ingress traffic to `api`'s pods is allowed. NetworkPolicies are
**additive**: a pod's effective policy is the union of every NetworkPolicy that selects it, and any
single policy that permits a given connection allows it - the deny-all policy above never
subtracts from what this new one grants.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the concept page states plainly that
NetworkPolicies are additive, so the effect of multiple policies selecting the same pod is
additive, and shows an example ingress rule (`ingress: - {}`) that allows all sources and ports.
