# q110-16: Inspect a chart's default values before installing

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-16-helm-show-values`

`setup.sh` staged a local Helm chart named `lookup` at
`questions/helm-crds/q110-16-helm-show-values/chart` (relative to `practice-bank/`). The chart
is not installed anywhere and has no other consumer - its `values.yaml` sets a top-level key
`region` to some default value you don't know in advance.

Without installing the chart, inspect the chart on disk to read its default `region` value.
Then create a ConfigMap named `chart-defaults` in namespace `q110-16-helm-show-values` with a
key `region` set to whatever value you found.

## Hint

Search kubernetes.io/docs for **"helm show values"** - the Helm CLI reference explains how to
print a chart's default `values.yaml` straight from a local chart directory (or a packaged
chart) without installing a release first.
