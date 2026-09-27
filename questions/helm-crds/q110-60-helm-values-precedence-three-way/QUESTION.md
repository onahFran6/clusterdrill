# q110-60-helm-values-precedence-three-way: Resolve a three-way values conflict across -f, --set, and --set-string

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-60-helm-values-precedence-three-way`

A local chart named `threeway` is on disk at
`questions/helm-crds/q110-60-helm-values-precedence-three-way/chart` (relative to
`practice-bank/`), with defaults `replicaCount: 1` and `extra.featureFlag: "off"`. A values
file at
`questions/helm-crds/q110-60-helm-values-precedence-three-way/chart-values/override-values.yaml`
contains:

```yaml
replicaCount: 3
```

Install release `threeway` into this namespace with **one command** that combines all three of:

- `-f` pointed at that `override-values.yaml`
- `--set replicaCount=5`
- both `--set extra.featureFlag=true` and `--set-string extra.featureFlag=true` on the same
  command

When done, Deployment `threeway-threeway` must have `5` replicas, and ConfigMap
`threeway-threeway-extra` must have `data.featureFlag` as the literal string `"true"` (a
boolean makes the ConfigMap invalid and the install fails).

## Hint

Search helm.sh/docs for **"helm values"** or **"helm install"** - the docs describe the
precedence order across a chart's own `values.yaml`, `-f` values files, `--set`, and
`--set-string`: each tier overrides the one before it, and `--set-string` always wins over a
plain `--set` for the same key regardless of which one appears first on the command line.
