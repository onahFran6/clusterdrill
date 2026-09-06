# q103-26: Fix a pod stuck Pending by a hard anti-affinity rule with nowhere to go

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-26-podantiaffinity-required-pending-on-single-node`

`setup.sh` already created two pods in namespace `q103-26-podantiaffinity-required-pending-on-single-node`,
both labeled `app: cache-replica`:

- `cache-0` is `Running`.
- `cache-1` is stuck `Pending`. Its `.spec.affinity.podAntiAffinity` declares a
  `requiredDuringSchedulingIgnoredDuringExecution` rule that forbids the scheduler from placing it on
  any node that already runs a pod matching label `app: cache-replica` (`topologyKey:
  kubernetes.io/hostname`). This cluster has exactly one node, and `cache-0` already occupies it, so
  `cache-1`'s hard requirement can never be satisfied. It will sit `Pending` forever - that is correct,
  observable Kubernetes scheduling behavior given the rule as written, not a bug to work around.

Diagnose why `cache-1` cannot schedule, then fix it so it reaches `Running`, without dropping the
anti-affinity intent altogether: replace `cache-1`'s `requiredDuringSchedulingIgnoredDuringExecution`
rule with an equivalent `preferredDuringSchedulingIgnoredDuringExecution` rule - same label selector
(`app: cache-replica`) and the same `topologyKey` (`kubernetes.io/hostname`) - so the scheduler still
*tries* to keep cache replicas on separate nodes when that's possible, but falls back to co-locating
them when, as on this single-node cluster, that is the only option.

`.spec.affinity` is immutable on an existing pod, so you cannot edit or patch it in place - delete and
recreate `cache-1` (same name `cache-1`, same image and command as it already has, same label
`app: cache-replica`). Leave `cache-0` alone entirely: do not delete, edit, or recreate it.

## Hint

Search kubernetes.io/docs for **"podAntiAffinity preferredDuringSchedulingIgnoredDuringExecution"** -
the "Assign Pods to Nodes" page's inter-pod affinity and anti-affinity section shows both the
`required` and `preferred` forms side by side and explains how a required rule can leave a pod
permanently unschedulable.
