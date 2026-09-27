# q103-31: Guarantee two cache replicas never share a node

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-31-podantiaffinity-required-running-on-two-nodes`

Two pods already exist in namespace `q103-31-podantiaffinity-required-running-on-two-nodes`,
both labeled `app: cache-replica` and both `Running`. Neither has an affinity rule, so nothing
stops them from landing on the same node.

`.spec.affinity` is immutable. Delete and recreate `cache-1` (same name, image, command, and
label `app: cache-replica`) with a `requiredDuringSchedulingIgnoredDuringExecution` pod
anti-affinity rule that forbids any node already running a pod labeled `app: cache-replica`
(`topologyKey: kubernetes.io/hostname`).

`cache-1` must reach `Running` on a different node from `cache-0`. Leave `cache-0` unchanged.

## Hint

Search kubernetes.io/docs for **"podAntiAffinity requiredDuringSchedulingIgnoredDuringExecution"** - the
"Assign Pods to Nodes" page's inter-pod affinity and anti-affinity section shows the required form and
explains `topologyKey`.
