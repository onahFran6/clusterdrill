# q108-52: Restrict ingress to the same namespace only

**Domain:** Services and Networking · **Points:** 7 · **Namespace:** `q108-52-networkpolicy-same-namespace-only-ingress`

A Deployment `internal-api` (pod-template label `app=internal-api`) already exists in namespace
`q108-52-networkpolicy-same-namespace-only-ingress`.

`internal-api` must only be reachable from other pods in its own namespace. No pod in any other
namespace should be able to reach it, regardless of that namespace's labels.

Create a NetworkPolicy named `internal-api-allow-same-namespace` in this namespace that:

- applies to pods matching `app=internal-api`
- allows **ingress** from any pod in the same namespace as this policy
- uses an ingress `from` entry that contains **only** an empty `podSelector: {}` and **no**
  `namespaceSelector` key at all

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the concept page's section on
`ipBlock`/`namespaceSelector`/`podSelector` peers explains that a `podSelector` alone (no
`namespaceSelector`) selects pods in the policy's own namespace and cannot match a pod outside
it. Adding a `namespaceSelector` is what opens the rule to other namespaces.
