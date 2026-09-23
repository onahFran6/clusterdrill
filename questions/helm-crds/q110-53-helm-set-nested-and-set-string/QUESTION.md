# q110-53: Nested --set overrides plus --set-string to stop a flag being coerced to bool

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-53-helm-set-nested-and-set-string`

`setup.sh` staged a local chart named `web` on disk at
`questions/helm-crds/q110-53-helm-set-nested-and-set-string/chart` (relative to the repo
root). Its `values.yaml` defaults are:

```yaml
ingress:
  enabled: false
  hosts:
    - host: chart-example.local
resources:
  limits:
    cpu: 100m
extra:
  buildFlag: "stable"
```

There's no time to write a values file - every override has to go in as `--set`/`--set-string`
flags on a single `helm install` command. Install a release named `web` into namespace
`q110-53-helm-set-nested-and-set-string` with:

- `ingress.enabled` set to `true` (the chart only renders an `Ingress` when this is true)
- The first entry of `ingress.hosts` with `host` set to `app.example.com`
- `resources.limits.cpu` set to `500m`
- `extra.buildFlag` set to the **literal string** `"true"` - the chart renders this value
  through `toYaml` into a ConfigMap's `data` field (which the Kubernetes API only accepts as
  `map[string]string`); if `buildFlag` lands as the boolean `true` instead of the string
  `"true"`, the ConfigMap is invalid and the **entire release fails to install** - so getting
  this one flag right is a precondition for everything else in this task succeeding.

## Hint

Search helm.sh/docs for **"helm install set"** or **"--set-string"** - the Helm docs on
`--set` explain how nested `key.path` overrides work, and why a numeric- or boolean-looking
value needs `--set-string` to survive as a literal string instead of being type-converted.
