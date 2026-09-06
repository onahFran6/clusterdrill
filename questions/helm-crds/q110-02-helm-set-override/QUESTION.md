# q110-02: Override a chart value at install time with `--set`

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-02-helm-set-override`

`setup.sh` staged a local Helm chart named `counter` at
`questions/helm-crds/q110-02-helm-set-override/chart` (relative to the `practice-bank/`
directory). Its default `values.yaml` sets `replicaCount: 1`.

Install this chart into namespace `q110-02-helm-set-override` under release name `ctr`,
overriding `replicaCount` to `3` at install time - without editing `values.yaml` on disk.

## Hint

Search kubernetes.io/docs for **"helm set values"** - the Helm values documentation shows how
`--set` overrides individual values from the command line without touching the chart's files.

