# q110-53-helm-set-nested-and-set-string: Nested --set overrides plus --set-string to stop a flag being coerced to bool

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-53-helm-set-nested-and-set-string`

A local Helm chart named `web` is on disk at
`questions/helm-crds/q110-53-helm-set-nested-and-set-string/chart` (relative to
`practice-bank/`). Its `values.yaml` defaults include:

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

Install a release named `web` into this namespace with a single `helm install`, overriding via
`--set` / `--set-string` only (no values file):

- `ingress.enabled` to `true` (the chart only renders an Ingress when this is true)
- the first `ingress.hosts` entry's `host` to `app.example.com`
- `resources.limits.cpu` to `500m`
- `extra.buildFlag` to the literal string `"true"` (not a boolean) - the chart renders this into
  a ConfigMap `data` field; a boolean value makes the ConfigMap invalid and the whole install
  fails

## Hint

Search helm.sh/docs for **"helm install set"** or **"--set-string"** - the Helm docs on
`--set` explain how nested `key.path` overrides work, and why a numeric- or boolean-looking
value needs `--set-string` to survive as a literal string instead of being type-converted.
