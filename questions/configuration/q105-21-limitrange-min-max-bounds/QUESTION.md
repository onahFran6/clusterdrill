# q105-21: Bound container memory with LimitRange min/max

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-21-limitrange-min-max-bounds`

Namespace `q105-21-limitrange-min-max-bounds` already exists but has no `LimitRange` yet. This is
a different `LimitRange` behavior from setting *defaults* - here you're setting hard *bounds* that
every container's own declared request must fall within.

Create a `LimitRange` named `mem-bounds` in that namespace, applying to `Container`-kind objects,
that requires every container's memory request to be **at least `64Mi`** and **at most `512Mi`**.

Then create a pod named `bounded-app` (image `nginx:1.25-alpine`) whose single container
explicitly requests `memory: 200Mi` - a value inside that range - and confirm the pod is admitted.

## Hint

Search kubernetes.io/docs for **"LimitRange constraints"** - the LimitRange concept page's
"Constraints on Resource Ranges" section shows the `min`/`max` fields, distinct from the
`default`/`defaultRequest` fields used elsewhere in this bank.
