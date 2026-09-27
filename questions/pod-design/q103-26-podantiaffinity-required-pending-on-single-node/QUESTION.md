# q103-26: Fix a pod stuck Pending by a hard anti-affinity rule with nowhere to go

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-26-podantiaffinity-required-pending-on-single-node`

Two pods already exist in namespace `q103-26-podantiaffinity-required-pending-on-single-node`,
both labeled `app: cache-replica`:

- `cache-0` is `Running`.
- `cache-1` is stuck `Pending`. Its `.spec.affinity.podAntiAffinity` is a
  `requiredDuringSchedulingIgnoredDuringExecution` rule for label `app: cache-replica`
  (`topologyKey: kubernetes.io/hostname`). This cluster has one node, and `cache-0` is already
  on it, so the hard rule cannot be satisfied.

Make `cache-1` reach `Running` without dropping anti-affinity. Replace the required rule with
`preferredDuringSchedulingIgnoredDuringExecution`, using the same label selector
(`app: cache-replica`) and the same `topologyKey` (`kubernetes.io/hostname`).

`.spec.affinity` is immutable. Delete and recreate `cache-1` with the same name, image, command,
and label `app: cache-replica`. Leave `cache-0` unchanged.

## Hint

Search kubernetes.io/docs for **"podAntiAffinity preferredDuringSchedulingIgnoredDuringExecution"** -
the "Assign Pods to Nodes" page's inter-pod affinity and anti-affinity section shows both the
`required` and `preferred` forms. A required rule on a single-node cluster leaves the second pod
Pending. Preferred still tries to spread replicas, then co-locates them when that is the only
option.
