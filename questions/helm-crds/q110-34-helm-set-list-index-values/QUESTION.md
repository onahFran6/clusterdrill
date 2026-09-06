# q110-34-helm-set-list-index-values: Override a list value's individual elements with --set

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-34-helm-set-list-index-values`

`setup.sh` staged a local Helm chart named `router` on disk at
`questions/helm-crds/q110-34-helm-set-list-index-values/chart` (relative to the
`practice-bank/` directory). The chart's default `values.yaml` declares `hosts` as a list with
one entry, `["default.example.com"]`, and templates a ConfigMap whose `hosts` key joins the list
with commas.

Install this chart into namespace `q110-34-helm-set-list-index-values` under release
name `demo`, overriding `hosts` at install time (via `--set`, not a values file) to a **list of
two** entries, in this exact order: `api.example.com`, then `admin.example.com` - use `--set`'s
`hosts[0]=...,hosts[1]=...` index syntax to set individual list elements directly on the command
line.

## Hint

Search kubernetes.io/docs for **"helm --set" "arrays"** - the Helm "Values Files" documentation
shows `--set` accepting an indexed syntax like `name[0]=value` to target a specific position in
a list value, letting you override list elements without writing a whole values file.
