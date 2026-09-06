# q103-31: Guarantee two cache replicas never share a node

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-31-podantiaffinity-required-running-on-two-nodes`

`setup.sh` already created two pods in namespace `q103-31-podantiaffinity-required-running-on-two-nodes`,
both labeled `app: cache-replica` and both `Running`:

- `cache-0` has no affinity rules at all.
- `cache-1` also has no affinity rules at all - nothing stops the scheduler from placing it on the
  same node as `cache-0`, which defeats the whole point of running two replicas for availability: a
  single node failure could take both of them down together.

Fix this by making the "never share a node" rule an actual scheduling guarantee, not a hope. `.spec.affinity`
is immutable on an existing pod, so you cannot edit or patch it in place - delete and recreate `cache-1`
(same name `cache-1`, same image and command as it already has, same label `app: cache-replica`), this time
with a `requiredDuringSchedulingIgnoredDuringExecution` pod anti-affinity rule that forbids the scheduler
from placing it on any node that already runs a pod matching label `app: cache-replica`
(`topologyKey: kubernetes.io/hostname`).

`cache-1` must reach `Running` again after you recreate it, and it must end up on a *different* node than
`cache-0`. Leave `cache-0` alone entirely: do not delete, edit, or recreate it.

## Hint

Search kubernetes.io/docs for **"podAntiAffinity requiredDuringSchedulingIgnoredDuringExecution"** - the
"Assign Pods to Nodes" page's inter-pod affinity and anti-affinity section shows the required form and
explains `topologyKey`.
