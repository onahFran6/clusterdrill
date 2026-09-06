# q108-32-networkpolicy-and-vs-or-selector-semantics: Fix an ingress NetworkPolicy that ORs its selectors instead of ANDing them

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-32-networkpolicy-and-vs-or-selector-semantics`

`setup.sh` already created a Deployment `payment-api` (pod-template label `app: payment-api`,
container port `8443`) in namespace `q108-32-networkpolicy-and-vs-or-selector-semantics`, along
with a NetworkPolicy named `allow-trusted-platform-clients` that is meant to enforce a strict
rule: only pods labeled `role: trusted-client` that are **also** running inside a namespace
labeled `team: platform` may connect to `payment-api`. A pod that satisfies only one of those two
conditions must never be let in.

The NetworkPolicy as written does not enforce that. Its single ingress rule's `from` list
currently has the `podSelector` and the `namespaceSelector` as **two separate list entries**:

```yaml
from:
  - podSelector:
      matchLabels:
        role: trusted-client
  - namespaceSelector:
      matchLabels:
        team: platform
```

Each entry in a `from` (or `to`) list is evaluated independently and the results are unioned -
this is an **OR**. As written, this policy actually allows connections from *either* any pod
anywhere labeled `role: trusted-client` (regardless of what namespace it runs in), *or* any pod
at all - regardless of its own labels - as long as it happens to be running in a namespace
labeled `team: platform`. Both of those are broader than intended: a pod that carries the
`role: trusted-client` label but lives in some unrelated, untrusted namespace is currently let
in, and so is a pod that carries no such label at all but happens to share a namespace with
trusted clients.

Fix the NetworkPolicy `allow-trusted-platform-clients` so the two selectors are combined as two
fields of the **same single entry** in the `from` list, which Kubernetes evaluates as an **AND**:
only a pod that matches `podSelector: role=trusted-client` **and** is running inside a namespace
that matches `namespaceSelector: team=platform` may connect. Concretely:

- the ingress rule's `from` list must contain **exactly one** entry
- that one entry must set **both** `podSelector.matchLabels.role: trusted-client` **and**
  `namespaceSelector.matchLabels.team: platform`
- leave everything else about the policy unchanged: it must still select `payment-api` pods via
  `podSelector.matchLabels.app: payment-api`, still set `policyTypes: [Ingress]`, and still
  restrict the allowed traffic to TCP port `8443`

## Hint

Search kubernetes.io/docs for **"Behavior of to and from selectors"** - the NetworkPolicy concept
page's section under that heading explains that multiple entries in one `from`/`to` list are
ORed together, while a `podSelector` and `namespaceSelector` set as two fields of the *same*
entry are ANDed together.
