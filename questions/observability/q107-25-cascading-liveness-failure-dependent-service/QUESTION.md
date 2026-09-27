# q107-25-cascading-liveness-failure-dependent-service: Trace a liveness-triggered restart loop back to a missing environment variable

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-25-cascading-liveness-failure-dependent-service`

A ConfigMap named `orders-config` and a pod named `orders-api` (image `busybox:1.36`) already
exist in namespace `q107-25-cascading-liveness-failure-dependent-service`. The pod is stuck in
`CrashLoopBackOff` and its container never becomes `Ready`. It also has a `livenessProbe`
(`tcpSocket` on port `8080`).

Fix the pod so that:

- the container's `LISTEN_PORT` environment variable still comes from a `configMapKeyRef`
  against ConfigMap `orders-config` in this namespace (do not switch to a literal value or a
  different ConfigMap)
- ConfigMap `orders-config`, the pod name `orders-api`, its namespace, its image `busybox:1.36`,
  its command, and its `livenessProbe` are left unchanged
- the container reaches `Ready` and stays `Ready` (no further restarts)

## Hint

Search kubernetes.io/docs for **"CreateContainerConfigError configmap"** - the Debug Pods page
covers how a Pod fails to even start its container when an env var's `configMapKeyRef` points at
a key that does not exist in the referenced ConfigMap, and how `kubectl describe pod` surfaces
that in its Events. Read Events before changing anything. The liveness probe would restart the
container if it failed after starting, but the container is exiting before the probe runs. Compare
the key `LISTEN_PORT` references with the keys that actually exist on `orders-config`.
