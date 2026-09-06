# q105-42-resourcequota-requires-explicit-resources: Fix a pod rejected for missing resource requests

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-42-resourcequota-requires-explicit-resources`

Namespace `q105-42-resourcequota-requires-explicit-resources` already has a `ResourceQuota` named
`strict-quota` that caps `requests.cpu`/`requests.memory`/`limits.cpu`/`limits.memory`. There is
no `LimitRange` in this namespace to fill in defaults.

A pod manifest is sitting on disk at `~/worker.yaml` (image `busybox:1.36`, running
`sleep 3600`), with no `resources` block at all. Applying it as-is is rejected: whenever a
namespace's `ResourceQuota` constrains `requests.cpu`/`requests.memory`, every pod in that
namespace must explicitly state its own `requests` and `limits` for those resources, or the API
server refuses to admit it.

Edit `~/worker.yaml` so its container explicitly sets `requests.cpu`, `requests.memory`,
`limits.cpu`, and `limits.memory` to any values that comfortably fit inside `strict-quota`'s
headroom, then apply it as a pod named `worker`. It must reach `Running`.

## Hint

Search kubernetes.io/docs for **"resource quota"** - the Resource Quotas concept page's "Requests
vs Limits" section explains why a `ResourceQuota` on `requests.cpu`/`requests.memory` forces every
pod in that namespace to declare its own requests and limits explicitly.
