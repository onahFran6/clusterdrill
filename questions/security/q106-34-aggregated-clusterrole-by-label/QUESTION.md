# q106-34: Extend a bound ServiceAccount's permissions through ClusterRole aggregation

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-34-aggregated-clusterrole-by-label`

Cluster-wide, a ClusterRole named `q106-34-monitoring-aggregate` already exists. Its
`aggregationRule` selects ClusterRoles labeled
`rbac.example.com/aggregate-to-q106-34-monitoring: "true"`, and its `rules` are empty. A
ClusterRoleBinding named `q106-34-monitoring-aggregate-binding` already grants that ClusterRole
to ServiceAccount `metrics-reader` in namespace
`q106-34-aggregated-clusterrole-by-label`, cluster-wide. `metrics-reader` cannot `get` or `list`
pods through this grant.

Do not edit `q106-34-monitoring-aggregate` or `q106-34-monitoring-aggregate-binding`. Create a
new ClusterRole named `q106-34-pod-reader` that:

- grants `get` and `list` on `pods` (core API group)
- is labeled `rbac.example.com/aggregate-to-q106-34-monitoring: "true"`
- is labeled `clusterdrill-question: q106-34-aggregated-clusterrole-by-label`

`metrics-reader` must then be able to `get` and `list` `pods` cluster-wide through the existing
aggregate role and binding.

## Hint

Search kubernetes.io/docs for **"Aggregated ClusterRoles"** - the RBAC concept page explains how
`aggregationRule.clusterRoleSelectors` copies rules from every matching ClusterRole into the
aggregate role. Aggregation is not instant. After you create `q106-34-pod-reader`, wait a few
seconds for `q106-34-monitoring-aggregate.rules` to update before you check permissions. The new
ClusterRole is cluster-scoped, so the `clusterdrill-question` label is what cleanup uses.
