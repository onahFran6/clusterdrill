# q108-16: Allow ingress only from a whole namespace

**Domain:** Services and Networking · **Points:** 7 · **Namespace:** `q108-16-networkpolicy-namespace-selector`

`setup.sh` already created a Deployment `shared-cache` (pod-template label `app=shared-cache`,
container port `6379`) in namespace `q108-16-networkpolicy-namespace-selector`, and labeled that
same namespace itself with `team=platform` (namespace labels are separate from pod labels - check
`kubectl get namespace q108-16-networkpolicy-namespace-selector --show-labels`).

Several other teams each have their own namespace and none of them should be able to reach
`shared-cache` - only pods running anywhere inside namespaces labeled `team=platform` should be
allowed in.

Create a NetworkPolicy named `shared-cache-allow-platform-ns` in this namespace that:

- applies to pods matching `app=shared-cache`
- allows **ingress** from any pod in any namespace matching the namespace label
  `team=platform` (this uses `namespaceSelector`, not `podSelector`, since the allowed source is
  defined by which namespace a pod lives in, not the pod's own labels)
- restricts the allowed traffic to TCP port `6379`

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the concept page's section on
`ipBlock`/`namespaceSelector`/`podSelector` peers shows a `namespaceSelector` example for allowing
traffic from every pod in namespaces that carry a given label.
