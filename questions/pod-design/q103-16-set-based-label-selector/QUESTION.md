# q103-16: Select pods by a set of allowed label values

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-16-set-based-label-selector`

Four pods already exist in namespace `q103-16-set-based-label-selector`, each labeled with
`region`:

- `svc-us` - `region=us`
- `svc-eu` - `region=eu`
- `svc-apac` - `region=apac`
- `svc-legacy` - `region=legacy`

Using one **set-based** selector (the `in` operator), find every pod whose `region` is `us` **or**
`eu`, then label each of those pods (and only those pods) with `active=true`.

## Hint

Search kubernetes.io/docs for **"kubectl label selector set-based requirement"** - the "Labels and
Selectors" concept page documents the set-based `in`, `notin`, and `exists` operators that
`kubectl get -l` also accepts. A comma-separated list of `key=value` pairs is equality-based
AND, not the `in` form this task asks for.
