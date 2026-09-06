# q106-34: Extend a bound ServiceAccount's permissions through ClusterRole aggregation

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-34-aggregated-clusterrole-by-label`

`setup.sh` already created, cluster-wide:

- a ClusterRole named `q106-34-monitoring-aggregate`, whose spec has an `aggregationRule` with a
  `clusterRoleSelectors` entry matching the label `rbac.example.com/aggregate-to-q106-34-monitoring:
  "true"` - but its `.rules` is currently empty, because no other ClusterRole in the cluster
  carries that label yet
- a ClusterRoleBinding named `q106-34-monitoring-aggregate-binding` that already grants
  `q106-34-monitoring-aggregate` to the ServiceAccount `metrics-reader` (in namespace
  `q106-34-aggregated-clusterrole-by-label`), cluster-wide

`metrics-reader` currently has no effective permissions from this binding, because the aggregate
role it's bound to has no rules yet.

Without editing `q106-34-monitoring-aggregate` or `q106-34-monitoring-aggregate-binding`
themselves, create a **new** ClusterRole named `q106-34-pod-reader` that:

- grants the `get` and `list` verbs on `pods` (core API group)
- carries the label `rbac.example.com/aggregate-to-q106-34-monitoring: "true"`

so that the aggregation controller folds its rules into `q106-34-monitoring-aggregate.rules`
automatically, and `metrics-reader` ends up able to `get`/`list` `pods` cluster-wide purely
through that aggregation - with no change to the existing ClusterRole or ClusterRoleBinding.

**Important:** `q106-34-pod-reader` is cluster-scoped and won't be cleaned up by deleting the
namespace - label it with `clusterdrill-question: q106-34-aggregated-clusterrole-by-label` too.

**Note:** aggregation is not instant - after you create the ClusterRole, allow a few seconds for
the controller to notice the label match and update `q106-34-monitoring-aggregate.rules` before
checking permissions.

## Hint

Search kubernetes.io/docs for **"Aggregated ClusterRoles"** - the RBAC concept page explains how
`aggregationRule.clusterRoleSelectors` causes the control plane to automatically combine
permissions from any ClusterRole matching the given label selector into the aggregate role's
`rules`.
