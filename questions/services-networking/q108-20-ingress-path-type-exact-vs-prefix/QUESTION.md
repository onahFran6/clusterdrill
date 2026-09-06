# q108-20: Fix an Ingress's pathType so exact and prefix matching behave correctly

**Domain:** Services and Networking · **Points:** 7 · **Namespace:** `q108-20-ingress-path-type-exact-vs-prefix`

`setup.sh` already created two backend Services (`status-svc` and `metrics-svc`, both port `80`)
and an Ingress named `diagnostics-ingress` (IngressClass `nginx`) in namespace
`q108-20-ingress-path-type-exact-vs-prefix`, but whoever wrote it swapped the intended
`pathType` for each rule:

- The `/status` path should match **only the literal path `/status`** and nothing under it
  (e.g. `/status/live` must NOT match this rule).
- The `/metrics` path should match `/metrics` **and any sub-path beneath it**
  (e.g. `/metrics/cpu` must match this rule).

Fix the Ingress so:

- the `/status` rule uses `pathType: Exact` and still routes to `status-svc` port `80`
- the `/metrics` rule uses `pathType: Prefix` and still routes to `metrics-svc` port `80`

Do not change the path strings, the backend service names, or the ports - only the `pathType` of
each rule needs to change.

## Hint

Search kubernetes.io/docs for **"Ingress path types"** - the Ingress concept page's "Path types"
section explains the difference between `Exact` (the URL path must match the `path` field
exactly, case-sensitively) and `Prefix` (matches based on a URL path element-by-element prefix).
