# q102-42-qos-guaranteed-mismatched-limits: One container's loose limits demote the whole Pod's QoS class

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-42-qos-guaranteed-mismatched-limits`

A Pod named `guaranteed-app` already exists in this namespace with two
containers:

- `app` (busybox:1.36) - `requests` and `limits` both set to `cpu: 100m,
  memory: 64Mi` (requests == limits).
- `cache` (busybox:1.36) - `requests` of `cpu: 50m, memory: 32Mi` but
  `limits` of `cpu: 100m, memory: 64Mi` (requests do **not** equal limits).

A Pod's overall QoS class (`.status.qosClass`) is only `Guaranteed` when
**every** container has `requests` exactly equal to `limits`, for both cpu
and memory. Because `cache`'s requests and limits differ, the whole Pod's
QoS class is `Burstable`, not `Guaranteed` - even though nothing crashes
and both containers run fine.

Fix `cache`'s `resources` so its `requests` exactly equal its `limits`
(`cpu: 100m, memory: 64Mi` for both), without changing `app` or either
container's image or command. This field is immutable on a running Pod -
delete and recreate `guaranteed-app` with the fix applied, keeping every
other field unchanged. Once fixed, `guaranteed-app`'s `.status.qosClass`
must be `Guaranteed`.

## Hint

Search kubernetes.io/docs for **"configure quality of service for pods"** -
the Pod QoS Classes concept page shows exactly what makes a Pod
`Guaranteed` versus `Burstable`, and that it's evaluated across every
container in the Pod, not just one.
