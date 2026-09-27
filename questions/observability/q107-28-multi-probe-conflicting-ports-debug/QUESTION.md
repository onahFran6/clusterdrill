# q107-28-multi-probe-conflicting-ports-debug: Fix three probes on one container that each target the wrong port after a service port change

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-28-multi-probe-conflicting-ports-debug`

A pod named `payments-gw` (image `nginx:1.25-alpine`) already exists in namespace
`q107-28-multi-probe-conflicting-ports-debug`. It stays at `0/1` and does not become Ready.
A ConfigMap named `nginx-conf` (key `default.conf`) is mounted into the pod.

Point `startupProbe`, `livenessProbe`, and `readinessProbe` `httpGet.port` at the port nginx
actually listens on, as declared in that ConfigMap. Do not change `containerPort` declarations,
the ConfigMap, or the volume mount. `payments-gw` must reach `1/1 Ready` and stay stable (no
further restarts).

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup probes"** - and remember
that per the "Protect slow starting containers with startup probes" section, `livenessProbe` and
`readinessProbe` are not even evaluated until `startupProbe` succeeds, so a startup probe pointed
at the wrong port can hide the fact all three probes are wrong. Read the listen port with
`kubectl get configmap nginx-conf -n q107-28-multi-probe-conflicting-ports-debug -o yaml`.
The probes still use the old port `80`.
