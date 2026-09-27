# q110-21-helm-multiple-value-files: Layer a custom values file over chart defaults

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-21-helm-multiple-value-files`

A local Helm chart named `stacker` is available at
`questions/helm-crds/q110-21-helm-multiple-value-files/chart` (relative to `practice-bank/`).
Its chart defaults include `image: nginx:1.25-alpine`, `replicaCount: 1`, and `envTier: dev`.
A sibling override file at
`questions/helm-crds/q110-21-helm-multiple-value-files/overrides/prod-values.yaml`
sets `replicaCount: 3` and `envTier: prod` (it does not set `image`).

Install the chart into this namespace as release `stack`, applying that override file on top of
the chart defaults. When done, Deployment `stack-stacker` must have `.spec.replicas` equal to
`3`, its pod template must carry the label `tier=prod`, and its container image must still be
`nginx:1.25-alpine`.

## Hint

Search kubernetes.io/docs and helm.sh/docs for **"helm install -f values file"** - the Helm
install command reference shows that `-f`/`--values` files are merged on top of a chart's own
`values.yaml`, overriding only the keys they set while leaving the rest at their chart defaults.
