# q105-48-limitrange-type-pod-aggregate: Fit a multi-container pod under a Pod-level LimitRange max

**Domain:** Application Environment, Configuration and Security · **Points:** 6 · **Namespace:** `q105-48-limitrange-type-pod-aggregate`

Namespace `q105-48-limitrange-type-pod-aggregate` already has a `LimitRange` named
`pod-aggregate-limits` with `type: Pod` (not `Container`) capping the **sum across every
container in a pod**: `max.cpu: 500m`, `max.memory: 512Mi`.

A pod manifest is sitting on disk at `~/multi-app.yaml` with two containers, `primary` and
`helper`, each requesting **and** limiting `cpu: 300m` / `memory: 300Mi`. Applying it as-is is
rejected: even though `300m`/`300Mi` might look reasonable per container, the LimitRange's
`type: Pod` bound applies to the **total** across both containers (`600m` CPU, `600Mi` memory
combined), which exceeds `pod-aggregate-limits`' `500m`/`512Mi` pod-level max.

Edit `~/multi-app.yaml` so the **sum** of both containers' CPU limits is at most `500m`, and the
**sum** of both containers' memory limits is at most `512Mi` (for example, `250m`/`256Mi` each).
Apply it as a pod named `multi-app`; both containers must reach `Running` (`2/2` ready).

## Hint

Search kubernetes.io/docs for **"limitrange"** - the LimitRange concept page's "Limit Range
Overview" section explains that a `type: Pod` limit constrains the total of all containers'
resources in a pod together, unlike a `type: Container` limit, which constrains each container
independently.
