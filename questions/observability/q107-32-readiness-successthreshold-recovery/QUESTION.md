# q107-32: Require multiple consecutive successes before a Pod is marked Ready

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-32-readiness-successthreshold-recovery`

A running Pod named `flaky-backend` (image `nginx:1.25-alpine`) already exists with an HTTP
`readinessProbe` on `path: /`, `port: 80`, `periodSeconds: 2`.

Set that probe so **3** consecutive successes are required before the Pod is Ready. Do not change
any other probe field. Confirm the Pod reaches Ready again.

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup probes"** - the pod
lifecycle docs cover `successThreshold`, which (unlike for liveness/startup probes, where it must
be `1`) can be set higher than 1 for a readiness probe. That stops the Pod flipping Ready on a
single successful probe after a brief failure.
