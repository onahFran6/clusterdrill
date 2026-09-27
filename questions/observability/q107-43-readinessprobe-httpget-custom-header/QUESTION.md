# q107-43: Add a required custom header to an HTTP readiness probe

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-43-readinessprobe-httpget-custom-header`

A running Pod named `api-gateway` (image `nginx:1.25-alpine`) already exists with a
`readinessProbe` on `path: /`, `port: 80`.

Add the header `X-Probe-Source: kubelet` to that `readinessProbe`. Do not change `path` or `port`.
Confirm the Pod reaches Ready again.

## Hint

Search kubernetes.io/docs for **"define a liveness HTTP request"** - the probes task page's
`httpGet` example includes an `httpHeaders` list for adding custom request headers, the same field
works for `readinessProbe` and `startupProbe` too.
