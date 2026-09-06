# q110-21-helm-multiple-value-files: Layer a custom values file over chart defaults

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-21-helm-multiple-value-files`

`setup.sh` already staged a local Helm chart named `stacker` at
`questions/helm-crds/q110-21-helm-multiple-value-files/chart` (relative to `practice-bank/`),
whose `values.yaml` defaults are `image: nginx:1.25-alpine`, `replicaCount: 1`, and
`envTier: dev`. It also wrote a sibling override file at
`questions/helm-crds/q110-21-helm-multiple-value-files/overrides/prod-values.yaml`
(NOT inside the chart directory) containing:

```yaml
replicaCount: 3
envTier: prod
```

Install the chart into namespace `q110-21-helm-multiple-value-files` as a Helm release named
`stack`, layering the `overrides/prod-values.yaml` file on top of the chart's defaults with
`-f questions/helm-crds/q110-21-helm-multiple-value-files/overrides/prod-values.yaml` so that
`replicaCount` and `envTier` come from the override file while every value the override file
does not set (such as the image) still comes from the chart's own `values.yaml`.

When done, the Deployment `stack-stacker` must have `.spec.replicas` equal to `3`, its pod
template must carry the label `tier=prod`, and its container image must still be
`nginx:1.25-alpine`.

## Hint

Search kubernetes.io/docs and helm.sh/docs for **"helm install -f values file"** - the Helm
install command reference shows that `-f`/`--values` files are merged on top of a chart's own
`values.yaml`, overriding only the keys they set while leaving the rest at their chart defaults.
