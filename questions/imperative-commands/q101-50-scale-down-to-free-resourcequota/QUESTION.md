# q101-50-scale-down-to-free-resourcequota: Free up quota headroom by scaling down before creating a new pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-50-scale-down-to-free-resourcequota`

`setup.sh` already created a ResourceQuota named `task-quota` capping this namespace's `pods` count
at `2`, and a Deployment named `legacy-batch` (image `busybox:1.36`, 2 replicas) that already uses
up that entire quota. Try creating a new pod right now with
`kubectl run report-gen --image=busybox:1.36 -- sleep 3600` and you'll see it rejected: the
namespace is already at its pod-count quota.

Diagnose why using `kubectl describe resourcequota task-quota` and `kubectl get pods`, then fix it
imperatively:

- Scale `legacy-batch` down to `1` replica (a single imperative `kubectl scale` command) to free up
  exactly one pod's worth of quota headroom - don't delete it outright, it's still needed.
- Then create a pod named `report-gen`, image `busybox:1.36`, running `sleep 3600`, using a single
  imperative `kubectl run` command.

## Hint

Search kubernetes.io/docs for **"resource quotas"** - the ResourceQuota concept page explains that
object count quotas (like a `pods` cap) reject new pod creation outright once the namespace is at
its limit, and that freeing existing pods (for example by scaling down another workload) is what
makes headroom for a new one.
