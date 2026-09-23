# q110-60: Resolve a three-way values conflict across -f, --set, and --set-string

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-60-helm-values-precedence-three-way`

`setup.sh` staged a local chart named `threeway` on disk at
`questions/helm-crds/q110-60-helm-values-precedence-three-way/chart` (relative to the repo
root), whose `values.yaml` defaults are `replicaCount: 1` and `extra.featureFlag: "off"`. It
also staged a values file at
`questions/helm-crds/q110-60-helm-values-precedence-three-way/chart-values/override-values.yaml` containing:

```yaml
replicaCount: 3
```

Install a release named `threeway` into namespace `q110-60-helm-values-precedence-three-way`
with **one command** that combines all three of:

- `-f` pointed at that `override-values.yaml` file
- `--set replicaCount=5`
- `--set extra.featureFlag=true` **and** `--set-string extra.featureFlag=true` (both, on the
  same command)

Work out - and then confirm from the running cluster state - what actually lands:

- Which source wins for `replicaCount`: the chart default (1), the values file (3), or the
  `--set` flag (5)?
- Which source wins for `extra.featureFlag`, and in what type: the boolean `true` from
  `--set`, or the literal string `"true"` from `--set-string`? (The chart renders this value
  through `toYaml` into a ConfigMap's `data` field, which only accepts strings - if the wrong
  type wins, the whole release fails to install.)

## Hint

Search helm.sh/docs for **"helm values"** or **"helm install"** - the docs describe the
precedence order across a chart's own `values.yaml`, `-f` values files, `--set`, and
`--set-string`: each tier overrides the one before it, and `--set-string` always wins over a
plain `--set` for the same key regardless of which one appears first on the command line.
