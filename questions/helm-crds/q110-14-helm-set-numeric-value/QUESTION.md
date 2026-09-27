# q110-14: Install a chart with four replicas

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-14-helm-set-numeric-value`

A local Helm chart named `scaler` is available at
`questions/helm-crds/q110-14-helm-set-numeric-value/chart` (relative to the `practice-bank/`
directory). Its default `values.yaml` sets `replicaCount: 1`.

Install this chart into namespace `q110-14-helm-set-numeric-value` under release name `grid`
so the resulting Deployment runs `4` replicas. Do not edit `values.yaml` on disk.

## Hint

Search kubernetes.io/docs for **"helm set values"** - the Helm values documentation shows how
`--set` overrides individual values from the command line without touching the chart's files
(for example `--set replicaCount=4`).
