# q108-52-networkpolicy-same-namespace-only-ingress: Restrict ingress to the same namespace only

**Domain:** Services and Networking · **Points:** 7 · **Namespace:** `q108-52-networkpolicy-same-namespace-only-ingress`

`setup.sh` already created a Deployment `internal-api` (pod-template label `app=internal-api`) in
namespace `q108-52-networkpolicy-same-namespace-only-ingress`.

`internal-api` must only be reachable from other pods in its own namespace - no pod in any other
namespace should be able to reach it, regardless of that namespace's labels.

Create a NetworkPolicy named `internal-api-allow-same-namespace` in this namespace that:

- applies to pods matching `app=internal-api`
- allows **ingress** from any pod in the *same* namespace as this policy - using an ingress `from`
  entry that contains **only** an empty `podSelector: {}` (matches every pod in the policy's own
  namespace) and **no** `namespaceSelector` key at all

This is a different shape from `q108-16`'s "allow from a labeled namespace" policy: adding a
`namespaceSelector` there is what lets pods from *other* namespaces in; a peer entry with only
`podSelector` and no `namespaceSelector` at all can never match a pod outside the policy's own
namespace, no matter how that other namespace is labeled.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the concept page's section on
`ipBlock`/`namespaceSelector`/`podSelector` peers explains that a `podSelector` alone (no
`namespaceSelector`) selects particular pods in the policy's own namespace.
