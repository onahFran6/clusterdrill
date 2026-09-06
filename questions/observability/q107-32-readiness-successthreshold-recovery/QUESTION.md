# q107-32: Require multiple consecutive successes before a Pod is marked Ready

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-32-readiness-successthreshold-recovery`

`setup.sh` already created a running Pod named `flaky-backend` (image `nginx:1.25-alpine`) with an
HTTP `readinessProbe` on `path: /`, `port: 80`, `periodSeconds: 2`. To avoid the Pod flapping
Ready/NotReady on a single lucky probe after a brief backend hiccup, require **3** consecutive
successful probes before it's considered Ready - without changing any other probe field - and
confirm it reaches Ready again.

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup probes"** - the pod
lifecycle docs cover `successThreshold`, which (unlike for liveness/startup probes, where it must
be `1`) can be set higher than 1 for a readiness probe.
