# q107-43: Add a required custom header to an HTTP readiness probe

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-43-readinessprobe-httpget-custom-header`

`setup.sh` already created a running Pod named `api-gateway` (image `nginx:1.25-alpine`) with a
`readinessProbe` on `path: /`, `port: 80`. This platform's health-check convention requires every
probe request to carry the header `X-Probe-Source: kubelet`. Add that header to `api-gateway`'s
`readinessProbe`, without changing `path` or `port`, and confirm it reaches Ready again.

## Hint

Search kubernetes.io/docs for **"define a liveness HTTP request"** - the probes task page's
`httpGet` example includes an `httpHeaders` list for adding custom request headers, the same field
works for `readinessProbe` and `startupProbe` too.
