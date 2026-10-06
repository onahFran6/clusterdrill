# q110-34-helm-set-list-index-values: Override a list value's individual elements with --set

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-34-helm-set-list-index-values`

A local Helm chart named `router` is on disk at
`$HOME/practice-work/q110-34-helm-set-list-index-values/chart`.
Its default `values.yaml` sets `hosts` to a one-element list, and a ConfigMap key `hosts` joins
that list with commas.

Install the chart into this namespace as release `demo`, overriding `hosts` at install time
(command-line `--set`, not a values file) to exactly two entries in this order:
`api.example.com`, then `admin.example.com`. ConfigMap `demo-router` must end up with
`hosts: api.example.com,admin.example.com`.

## Hint

Search kubernetes.io/docs for **"helm --set" "arrays"** - the Helm "Values Files" documentation
shows `--set` accepting an indexed syntax like `name[0]=value` to target a specific position in
a list value, letting you override list elements without writing a whole values file.
