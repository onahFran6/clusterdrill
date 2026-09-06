# q108-50-networkpolicy-ipblock-peer-exclusivity-fix: Fix a NetworkPolicy peer that illegally mixes ipBlock and podSelector

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-50-networkpolicy-ipblock-peer-exclusivity-fix`

`setup.sh` already created a Deployment named `partner-gateway` (pod-template label
`app: partner-gateway`) in namespace
`q108-50-networkpolicy-ipblock-peer-exclusivity-fix`. It also wrote a NetworkPolicy
manifest to
`~/practice-work/q108-50-networkpolicy-ipblock-peer-exclusivity-fix/netpol.yaml`,
meant to allow ingress to `partner-gateway`'s pods from **any one** of three separate sources:

- pods labeled `role: internal-caller`
- the external CIDR block `203.0.113.0/24` (a partner's fixed egress range)
- pods labeled `role: metrics-scraper` running in a namespace labeled `team: observability`

It has **not** been applied yet - applying it as written fails validation, because its `from` list
has only **one** entry that tries to set `podSelector`, `ipBlock`, *and* `namespaceSelector` all on
the same `NetworkPolicyPeer`. A single peer entry may combine `podSelector` with
`namespaceSelector` (which ANDs them), but `ipBlock` may never appear alongside either of them in
the same entry - the API rejects it outright.

Fix the file so it expresses the three sources correctly as **three separate entries** in the
`from` list (which OR's them together, matching "any one of"):

- one entry with only `podSelector.matchLabels.role: internal-caller`
- one entry with only `ipBlock.cidr: 203.0.113.0/24`
- one entry combining `podSelector.matchLabels.role: metrics-scraper` **and**
  `namespaceSelector.matchLabels.team: observability` on that single entry

Then apply it. Leave the policy's own `podSelector` (`app: partner-gateway`), `policyTypes`, and
port (`TCP 443`) unchanged.

## Hint

Search kubernetes.io/docs for **"ipBlock" "NetworkPolicyPeer"** - the NetworkPolicy API reference
for `NetworkPolicyPeer` states that exactly one of `podSelector`/`namespaceSelector` (which may be
combined together) or `ipBlock` (which may not be combined with either) may be set per entry.
