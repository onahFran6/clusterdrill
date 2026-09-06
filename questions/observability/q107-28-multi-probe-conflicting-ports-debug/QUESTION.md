# q107-28-multi-probe-conflicting-ports-debug: Fix three probes on one container that each target the wrong port after a service port change

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-28-multi-probe-conflicting-ports-debug`

`setup.sh` created a pod named `payments-gw` (image `nginx:1.25-alpine`) in namespace
`q107-28-multi-probe-conflicting-ports-debug`. Someone recently changed nginx's actual listening
port via a mounted ConfigMap named `nginx-conf` (key `default.conf`) but forgot to update the
probes to match. Right now:

```sh
kubectl get pod payments-gw -n q107-28-multi-probe-conflicting-ports-debug
```

shows the pod stuck at `0/1` and eventually cycling through `CrashLoopBackOff` - the container
never gets marked started, so liveness/readiness probes never even run, and once `startupProbe`
finally exhausts its failure threshold the container is killed and restarted, forever.

Inspect the mounted ConfigMap to find the real listen port:

```sh
kubectl get configmap nginx-conf -n q107-28-multi-probe-conflicting-ports-debug -o yaml
```

Then edit the pod's `startupProbe`, `livenessProbe`, and `readinessProbe` so all three
`httpGet.port` fields match the ConfigMap's real listen port instead of the stale value `80`.
Do not change `containerPort` declarations, the ConfigMap, or the volume mount - only the three
probes' ports need fixing. When you're done, `payments-gw` must reach `1/1 Ready` and stay stable
(no further restarts).

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup probes"** - and remember
that per the "Protect slow starting containers with startup probes" section, `livenessProbe` and
`readinessProbe` are not even evaluated until `startupProbe` succeeds, so a startup probe pointed
at the wrong port can hide the fact all three probes are wrong.
