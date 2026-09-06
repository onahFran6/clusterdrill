# q105-28-limitrange-default-vs-explicit-request: Reconcile a LimitRange default against an explicit over-limit request

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-28-limitrange-default-vs-explicit-request`

`setup.sh` already created a `LimitRange` named `container-limits` in namespace
`q105-28-limitrange-default-vs-explicit-request` that caps every container's memory **limit** at
`256Mi` and sets a default memory **request** of `128Mi` for any container that doesn't declare
its own request.

A manifest at `~/bigmem.yaml` in your terminal's working directory defines a pod named `bigmem`
whose single container sets `resources.limits.memory: 512Mi` and declares no `resources.requests`
at all.

Apply it as-is first and observe what happens.

Then diagnose why it was rejected: `512Mi` exceeds the `LimitRange`'s `256Mi` maximum. Note also
that Kubernetes defaults an unset request to match an explicitly-set limit on the same container -
it does **not** fall back to the `LimitRange`'s `defaultRequest` once a limit is present - so
simply lowering the limit is not enough to end up with the namespace's `128Mi` default request.

Edit `~/bigmem.yaml` so the container's memory **limit** is exactly `200Mi` and its memory
**request** is exactly `128Mi` (matching the `LimitRange`'s own default request value), and apply
it successfully. Do not modify the `container-limits` `LimitRange` itself - fix this by changing
the pod, not the constraint. When you're done, pod `bigmem` must be `Running` with
`resources.limits.memory` = `200Mi` and `resources.requests.memory` = `128Mi` on its container.

## Hint

Search kubernetes.io/docs for **"LimitRange constraints"** - the LimitRange concept page's
"Constraints on Resource Ranges" section explains how a container's declared limit is validated
against the `LimitRange`'s max, and how `defaultRequest` fills in a request that was left unset.
