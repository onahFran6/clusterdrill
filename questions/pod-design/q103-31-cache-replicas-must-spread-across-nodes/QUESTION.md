# q103-31: Guarantee two cache replicas never share a node

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-31-cache-replicas-must-spread-across-nodes`

Two pods already exist in namespace `q103-31-cache-replicas-must-spread-across-nodes`,
both labeled `app: cache-replica` and both `Running`. Neither has an affinity rule, so nothing
stops them from landing on the same node.

Make sure `cache-1` runs on a different node from `cache-0` - permanently, as a guarantee the
scheduler must always honor, not just an initial best effort. Keep `cache-1`'s name, image,
command, and `app: cache-replica` label. Leave `cache-0` unchanged.

## Hint

Search kubernetes.io/docs for **"inter-pod affinity and anti-affinity"** - the "Assign Pods to
Nodes" page shows two strengths for expressing a rule like this; only one of them is actually
enforced by the scheduler every time, not merely attempted. `spec.affinity` can't be patched
onto a pod that already exists.
