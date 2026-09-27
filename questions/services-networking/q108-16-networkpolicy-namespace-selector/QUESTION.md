# q108-16: Allow ingress only from a whole namespace

**Domain:** Services and Networking · **Points:** 7 · **Namespace:** `q108-16-networkpolicy-namespace-selector`

A Deployment `shared-cache` (pod-template label `app=shared-cache`,
container port `6379`) already exists in namespace `q108-16-networkpolicy-namespace-selector`.
That namespace is labeled `team=platform`.

Only pods running inside namespaces labeled `team=platform` should be able to reach
`shared-cache`. Pods in other namespaces must not.

Create a NetworkPolicy named `shared-cache-allow-platform-ns` in this namespace that:

- applies to pods matching `app=shared-cache`
- allows **ingress** from any pod in any namespace matching the namespace label `team=platform`
- restricts the allowed traffic to TCP port `6379`

Select the source by the namespace's label, not by a pod label.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the concept page's section on
`ipBlock`/`namespaceSelector`/`podSelector` peers shows a `namespaceSelector` example for allowing
traffic from every pod in namespaces that carry a given label. Namespace labels are separate from
pod labels (`kubectl get namespace <name> --show-labels`).
