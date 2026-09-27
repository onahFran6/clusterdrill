# q101-50: Free ResourceQuota headroom, then create a Pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-50-scale-down-to-free-resourcequota`

A ResourceQuota named `task-quota` caps this namespace's `pods` count at `2`, and a Deployment
named `legacy-batch` (image `busybox:1.36`, 2 replicas) already uses that entire quota. Creating a
new Pod with `kubectl run report-gen --image=busybox:1.36 -- sleep 3600` is rejected.

Investigate with `kubectl describe resourcequota task-quota` and `kubectl get pods`, then:

- Scale `legacy-batch` down to `1` replica (a single imperative `kubectl scale` command) to free
  one Pod's worth of quota - do not delete the Deployment.
- Create a Pod named `report-gen`, image `busybox:1.36`, running `sleep 3600`, using a single
  imperative `kubectl run` command.

## Hint

Search kubernetes.io/docs for **"resource quotas"** - the ResourceQuota concept page explains that
object count quotas (like a `pods` cap) reject new pod creation outright once the namespace is at
its limit, and that freeing existing pods (for example by scaling down another workload) is what
makes headroom for a new one.
