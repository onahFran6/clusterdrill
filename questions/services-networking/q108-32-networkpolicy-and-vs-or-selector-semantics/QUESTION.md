# q108-32: Require both a pod label and a namespace label on one ingress rule

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-32-networkpolicy-and-vs-or-selector-semantics`

A Deployment `payment-api` (pod-template label `app: payment-api`,
container port `8443`) already exists in namespace
`q108-32-networkpolicy-and-vs-or-selector-semantics`, along with a NetworkPolicy named
`allow-trusted-platform-clients`. The policy is meant to allow a connection only when the client
pod is labeled `role: trusted-client` **and** that pod is running in a namespace labeled
`team: platform`. A pod that satisfies only one of those conditions must not be allowed in.

The policy does not enforce that today. Its `from` list treats the two selectors as alternatives.

Fix `allow-trusted-platform-clients` so both selectors apply together:

- the ingress rule's `from` list must contain **exactly one** entry
- that one entry must set **both** `podSelector.matchLabels.role: trusted-client` **and**
  `namespaceSelector.matchLabels.team: platform`
- leave everything else unchanged: it must still select `payment-api` pods via
  `podSelector.matchLabels.app: payment-api`, still set `policyTypes: [Ingress]`, and still
  restrict the allowed traffic to TCP port `8443`

## Hint

Search kubernetes.io/docs for **"Behavior of to and from selectors"** - the NetworkPolicy concept
page explains that multiple entries in one `from`/`to` list are ORed together, while a
`podSelector` and `namespaceSelector` set as two fields of the same entry are ANDed. The broken
form is two separate list items, one for each selector.
