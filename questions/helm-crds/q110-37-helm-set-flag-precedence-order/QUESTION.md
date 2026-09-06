# q110-37-helm-set-flag-precedence-order: Later --set flags win over earlier ones for the same key

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-37-helm-set-flag-precedence-order`

`setup.sh` staged a local Helm chart named `tuner` on disk at
`questions/helm-crds/q110-37-helm-set-flag-precedence-order/chart` (relative to the
`practice-bank/` directory). The chart's default `values.yaml` sets `logLevel: info` and
templates a ConfigMap key `logLevel` from `.Values.logLevel`.

Install this chart into namespace `q110-37-helm-set-flag-precedence-order` under release name
`demo`, passing **two** separate `--set logLevel=...` flags on the same command line: first
`--set logLevel=debug`, then `--set logLevel=warn`. When the same key is set more than once
across multiple `--set` flags, the **last** one on the command line wins - the final ConfigMap
must end up with `logLevel: warn`, not `debug`.

## Hint

Search kubernetes.io/docs for **"helm --set" "merge"** - the Helm "Values Files" documentation
explains that when multiple `--set`/`--set-string`/`-f` sources set the same key, later sources
on the command line override earlier ones, the same left-to-right precedence rule that applies
across multiple `-f` values files.
