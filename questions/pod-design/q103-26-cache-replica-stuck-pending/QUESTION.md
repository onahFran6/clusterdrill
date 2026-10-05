# q103-26: Let a cache replica run somewhere, even when it can't have its own node

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-26-cache-replica-stuck-pending`

Neutrino Computing Center runs `cache-replica` pods that should avoid landing on the same node
as each other when there's room to spread out - but this cluster only has one node, and
`cache-0` is already on it.

Two pods already exist in namespace `q103-26-cache-replica-stuck-pending`,
both labeled `app: cache-replica`:

- `cache-0` is `Running`.
- `cache-1` is stuck `Pending`, and will stay that way forever as it's currently configured.

Make `cache-1` reach `Running` on this single node, without abandoning the intent to keep
replicas apart whenever that's actually achievable. Leave `cache-0` unchanged, and keep
`cache-1`'s name, image, command, and `app: cache-replica` label.

## Hint

Search kubernetes.io/docs for **"inter-pod affinity and anti-affinity"** - the "Assign Pods to
Nodes" page shows two strengths for expressing a rule like this: one can leave a pod Pending
forever if the cluster can never satisfy it, the other only ever expresses a preference.
`spec.affinity` can't be patched onto a pod that already exists.
