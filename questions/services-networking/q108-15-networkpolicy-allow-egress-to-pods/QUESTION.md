# q108-15: Restrict a pod's egress to one specific destination

**Domain:** Services and Networking · **Points:** 7 · **Namespace:** `q108-15-networkpolicy-allow-egress-to-pods`

Two Deployments already exist in namespace
`q108-15-networkpolicy-allow-egress-to-pods`:

- `report-generator` (pod-template label `app=report-generator`) - should only be able to reach
  one internal dependency
- `metrics-store` (pod-template label `app=metrics-store`, container port `9090`) - the one
  destination `report-generator` is allowed to call

Create a NetworkPolicy named `report-generator-restrict-egress` in this namespace that:

- applies to pods matching `app=report-generator`
- allows **egress** traffic only to pods matching `app=metrics-store`
- restricts the allowed egress traffic to TCP port `9090`

Set `policyTypes` to include `Egress`. Do not add a catch-all allow rule.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the concept page's example manifest
shows an `egress[].to[].podSelector` combined with an `egress[].ports` entry. With
`policyTypes: [Egress]` and no catch-all egress entry, any other outbound destination from
`report-generator` (including DNS, unless a separate rule allows it) is outside what this policy
permits.
