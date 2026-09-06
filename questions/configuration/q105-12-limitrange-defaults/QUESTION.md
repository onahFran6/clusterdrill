# q105-12: Set namespace-wide default resource requests and limits

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-12-limitrange-defaults`

Namespace `q105-12-limitrange-defaults` already exists but has no `LimitRange` yet.

Create a `LimitRange` named `container-defaults` in that namespace, applying to `Container`-kind
objects, that sets:

- default CPU limit: `200m`, default memory limit: `256Mi`
- default CPU request: `100m`, default memory request: `128Mi`

Then create a pod named `plain-app` (image `nginx:1.25-alpine`) in that namespace **without
specifying any `resources` field at all** on its container, and confirm the LimitRange's defaults
were applied automatically.

## Hint

Search kubernetes.io/docs for **"LimitRange default"** - the Configure Default Memory Requests
and Limits for a Namespace task shows the `LimitRange` object's `default`/`defaultRequest` fields
and how they apply to pods that don't set their own.
