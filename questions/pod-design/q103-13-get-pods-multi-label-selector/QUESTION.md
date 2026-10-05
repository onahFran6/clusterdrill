# q103-13: Find pods matching two labels at once

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-13-get-pods-multi-label-selector`

Neutrino Computing Center tags its detector-feed pods by `tier` and deployment `env` so the
platform team can always find one exact combination fast. Four pods already exist in namespace
`q103-13-get-pods-multi-label-selector`:

- `frontend-a` - labels `tier=frontend`, `env=prod`
- `frontend-b` - labels `tier=frontend`, `env=staging`
- `backend-a` - labels `tier=backend`, `env=prod`
- `backend-b` - labels `tier=backend`, `env=staging`

Using one label selector (not manual filtering), find the pod that is **both** `tier=frontend`
**and** `env=prod`, then label that pod (and only that pod) with `verified=true`.

## Hint

Search kubernetes.io/docs for **"kubectl get labels selector"** - the `kubectl get` command
reference's `-l`/`--selector` flag shows how to combine multiple `key=value` requirements with a
comma to mean AND.
