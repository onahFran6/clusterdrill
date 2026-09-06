# q107-25-cascading-liveness-failure-dependent-service: Trace a liveness-triggered restart loop back to a missing environment variable

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-25-cascading-liveness-failure-dependent-service`

`setup.sh` already created a ConfigMap named `orders-config` (key `PORT` = `8080`) and a pod
named `orders-api` (image `busybox:1.36`) in namespace
`q107-25-cascading-liveness-failure-dependent-service`. The pod is stuck in
`CrashLoopBackOff` and its container never becomes `Ready`.

The pod also defines a `livenessProbe` (`tcpSocket` on port `8080`) that would restart the
container if it ever failed after starting - but that is not what is happening here: the
container is exiting immediately, every time, before the probe gets a chance to run at all.

Run `kubectl describe pod orders-api -n q107-25-cascading-liveness-failure-dependent-service`
and read the Events section carefully to find the real root cause before you touch anything.

Fix the pod so that:

- the container's `LISTEN_PORT` environment variable still comes from a `configMapKeyRef`
  against ConfigMap `orders-config` in this namespace (do not switch to a literal value or a
  different ConfigMap)
- the `configMapKeyRef.key` is corrected to a key that actually exists in `orders-config`
- the ConfigMap `orders-config`, the pod name `orders-api`, its namespace, its image
  `busybox:1.36`, its command, and its `livenessProbe` are all left unchanged
- the pod's container reaches `Ready` and stays `Ready` (no further restarts) once fixed

## Hint

Search kubernetes.io/docs for **"CreateContainerConfigError configmap"** - the Debug Pods page
covers how a Pod fails to even start its container when an env var's `configMapKeyRef` points at
a key that does not exist in the referenced ConfigMap, and how `kubectl describe pod` surfaces
that in its Events.
