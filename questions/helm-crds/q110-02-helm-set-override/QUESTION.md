# q110-02: Install a chart with a non-default replica count

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-02-helm-set-override`

A local Helm chart named `counter` is available at
`$HOME/practice-work/q110-02-helm-set-override/chart`. Its default `values.yaml` sets
`replicaCount: 1`.

Install this chart into namespace `q110-02-helm-set-override` under release name `ctr` so
the resulting Deployment runs `3` replicas. Do not edit `values.yaml` on disk.

## Hint

Search kubernetes.io/docs for **"helm set values"** - the Helm values documentation shows how
`--set` overrides individual values from the command line without touching the chart's files.
