# q110-11: Install a chart that bundles its own CRD

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-11-helm-chart-with-crd`

`setup.sh` staged a local Helm chart named `bakery` at
`questions/helm-crds/q110-11-helm-chart-with-crd/chart` (relative to `practice-bank/`). The
chart's `crds/` directory bundles a `CustomResourceDefinition` (kind `Cake`, group
`bakery.clusterdrill.io/v1`), and its `templates/` directory creates one `Cake` custom
resource using the chart's default `flavor` value (`vanilla`).

Install this chart into namespace `q110-11-helm-chart-with-crd` under release name `batch1`.
Neither the CRD nor the `Cake` instance exist yet - installing the chart must create both.

## Hint

Search kubernetes.io/docs for **"helm crds"** - the Helm "Custom Resource Definitions" docs
explain the special, non-templated `crds/` directory convention: those objects install once,
before every other template in the chart, and are never touched by `helm upgrade`.

