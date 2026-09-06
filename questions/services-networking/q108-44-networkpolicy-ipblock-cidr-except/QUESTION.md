# q108-44-networkpolicy-ipblock-cidr-except: Restrict egress to a CIDR range with a carved-out exception

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-44-networkpolicy-ipblock-cidr-except`

`setup.sh` already created a Deployment named `analytics` (pod-template label `app=analytics`) in
namespace `q108-44-networkpolicy-ipblock-cidr-except`.

Create a NetworkPolicy named `analytics-restrict-egress-cidr` that:

- selects pods with `podSelector.matchLabels.app: analytics`
- sets `policyTypes: [Egress]`
- has exactly one `egress` rule whose single `to` entry allows traffic to the CIDR block
  `10.0.0.0/8`, **except** the sub-range `10.0.5.0/24` (an internal quarantine range analytics
  must never reach directly)

## Hint

Search kubernetes.io/docs for **"ipBlock"** - the NetworkPolicy concept page's IPBlock section
shows `to[].ipBlock.cidr` alongside an optional `to[].ipBlock.except` list of narrower CIDRs to
carve back out of the allowed range.
