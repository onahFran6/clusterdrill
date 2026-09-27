# q108-50: Fix a NetworkPolicy peer that illegally mixes ipBlock and podSelector

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-50-networkpolicy-ipblock-peer-exclusivity-fix`

A Deployment named `partner-gateway` (pod-template label
`app: partner-gateway`) already exists in namespace
`q108-50-networkpolicy-ipblock-peer-exclusivity-fix`. A NetworkPolicy manifest at
`~/practice-work/q108-50-networkpolicy-ipblock-peer-exclusivity-fix/netpol.yaml` is meant to allow
ingress to `partner-gateway`'s pods from **any one** of three sources:

- pods labeled `role: internal-caller`
- the external CIDR block `203.0.113.0/24`
- pods labeled `role: metrics-scraper` running in a namespace labeled `team: observability`

The file has not been applied. Applying it as written fails validation.

Fix the file so the three sources are **three separate entries** in the `from` list:

- one entry with only `podSelector.matchLabels.role: internal-caller`
- one entry with only `ipBlock.cidr: 203.0.113.0/24`
- one entry combining `podSelector.matchLabels.role: metrics-scraper` **and**
  `namespaceSelector.matchLabels.team: observability` on that single entry

Then apply it. Leave the policy's own `podSelector` (`app: partner-gateway`), `policyTypes`, and
port (`TCP 443`) unchanged.

## Hint

Search kubernetes.io/docs for **"ipBlock" "NetworkPolicyPeer"** - the NetworkPolicy API reference
says a single peer may combine `podSelector` with `namespaceSelector` (AND), but `ipBlock` may
never appear alongside either of them in the same entry. Separate `from` entries are ORed, which
is the "any one of these sources" shape. The current file puts all three fields on one peer.
