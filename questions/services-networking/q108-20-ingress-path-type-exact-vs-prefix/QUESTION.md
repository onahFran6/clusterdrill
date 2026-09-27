# q108-20: Fix an Ingress's pathType so exact and prefix matching behave correctly

**Domain:** Services and Networking · **Points:** 7 · **Namespace:** `q108-20-ingress-path-type-exact-vs-prefix`

Two backend Services (`status-svc` and `metrics-svc`, both port `80`)
and an Ingress named `diagnostics-ingress` (IngressClass `nginx`) already exist in namespace
`q108-20-ingress-path-type-exact-vs-prefix`. The `pathType` on each rule is the wrong kind of match:

- The `/status` path should match **only the literal path `/status`** and nothing under it
  (for example `/status/live` must not match this rule).
- The `/metrics` path should match `/metrics` **and any sub-path beneath it**
  (for example `/metrics/cpu` must match this rule).

Fix the Ingress so:

- the `/status` rule uses `pathType: Exact` and still routes to `status-svc` port `80`
- the `/metrics` rule uses `pathType: Prefix` and still routes to `metrics-svc` port `80`

Do not change the path strings, the backend service names, or the ports.

## Hint

Search kubernetes.io/docs for **"Ingress path types"** - the Ingress concept page's "Path types"
section explains the difference between `Exact` (the URL path must match the `path` field
exactly, case-sensitively) and `Prefix` (matches based on a URL path element-by-element prefix).
