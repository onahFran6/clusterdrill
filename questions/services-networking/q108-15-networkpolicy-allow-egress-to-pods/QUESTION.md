# q108-15: Restrict a pod's egress to one specific destination

**Domain:** Services and Networking · **Points:** 7 · **Namespace:** `q108-15-networkpolicy-allow-egress-to-pods`

`setup.sh` already created two Deployments in namespace
`q108-15-networkpolicy-allow-egress-to-pods`:

- `report-generator` (pod-template label `app=report-generator`) - should only be able to reach
  one internal dependency, nothing else
- `metrics-store` (pod-template label `app=metrics-store`, container port `9090`) - the one
  destination `report-generator` is allowed to call

Create a NetworkPolicy named `report-generator-restrict-egress` in this namespace that:

- applies to pods matching `app=report-generator` (the policy's `podSelector`)
- allows **egress** traffic only to pods matching `app=metrics-store`
- restricts the allowed egress traffic to TCP port `9090`

Because this policy sets `policyTypes: [Egress]` with a defined `egress` rule and no catch-all
"allow everything" entry, any other outbound destination from `report-generator` (including DNS,
unless a separate rule allows it) falls outside what this policy permits.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the same concept page's example
manifest also shows an `egress[].to[].podSelector` combined with an `egress[].ports` entry, mirror
image of the ingress side.
