# q110-37-helm-set-flag-precedence-order: Later --set flags win over earlier ones for the same key

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-37-helm-set-flag-precedence-order`

A local Helm chart named `tuner` is on disk at
`questions/helm-crds/q110-37-helm-set-flag-precedence-order/chart` (relative to
`practice-bank/`). Its default `values.yaml` sets `logLevel: info`, and a ConfigMap key
`logLevel` is rendered from `.Values.logLevel`.

Install the chart into this namespace as release `demo`, passing two separate
`--set logLevel=...` flags on the same command: first `logLevel=debug`, then `logLevel=warn`.
ConfigMap `demo-tuner` must end up with `logLevel: warn`.

## Hint

Search kubernetes.io/docs for **"helm --set" "merge"** - the Helm "Values Files" documentation
explains that when multiple `--set`/`--set-string`/`-f` sources set the same key, later sources
on the command line override earlier ones, the same left-to-right precedence rule that applies
across multiple `-f` values files.
