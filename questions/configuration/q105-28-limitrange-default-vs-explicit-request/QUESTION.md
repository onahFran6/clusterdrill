# q105-28: Fix a Pod that exceeds a LimitRange memory max

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-28-limitrange-default-vs-explicit-request`

A `LimitRange` named `container-limits` already exists in namespace
`q105-28-limitrange-default-vs-explicit-request` that caps every container's memory **limit** at
`256Mi` and sets a default memory **request** of `128Mi` for any container that doesn't declare
its own request.

A manifest at `~/bigmem.yaml` in your terminal's working directory defines a Pod named `bigmem`
whose single container sets `resources.limits.memory: 512Mi` and declares no `resources.requests`
at all.

Apply it as-is first and observe what happens. Then edit `~/bigmem.yaml` so the container's
memory **limit** is exactly `200Mi` and its memory **request** is exactly `128Mi`, and apply it
successfully. Do not modify the `container-limits` `LimitRange` itself - fix this by changing the
pod, not the constraint.

When you're done, Pod `bigmem` must be `Running` with `resources.limits.memory` = `200Mi` and
`resources.requests.memory` = `128Mi` on its container.

## Hint

Search kubernetes.io/docs for **"LimitRange constraints"** - the LimitRange concept page's
"Constraints on Resource Ranges" section explains how a container's declared limit is validated
against the `LimitRange`'s max, and how `defaultRequest` fills in a request that was left unset.
