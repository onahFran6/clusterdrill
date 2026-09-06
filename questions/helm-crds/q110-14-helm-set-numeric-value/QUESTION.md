# q110-14: Override a numeric replica count at install time

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-14-helm-set-numeric-value`

`setup.sh` staged a local Helm chart named `scaler` at
`questions/helm-crds/q110-14-helm-set-numeric-value/chart` (relative to the `practice-bank/`
directory). Its default `values.yaml` sets `replicaCount: 1`.

Install this chart into namespace `q110-14-helm-set-numeric-value` under release name `grid`,
overriding `replicaCount` to `4` at install time using `--set replicaCount=4` - without editing
`values.yaml` on disk.

## Hint

Search kubernetes.io/docs for **"helm set values"** - the Helm values documentation shows how
`--set` overrides individual values from the command line without touching the chart's files.
