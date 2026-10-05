# q110-16: Record a chart's default region value

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-16-helm-show-values`

A local Helm chart named `lookup` is available at
`$HOME/practice-work/q110-16-helm-show-values/chart`. The chart
is not installed anywhere - its `values.yaml` sets a top-level key `region` to some default
value you don't know in advance.

Without installing the chart, inspect the chart on disk to read its default `region` value.
Then create a ConfigMap named `chart-defaults` in namespace `q110-16-helm-show-values` with a
key `region` set to whatever value you found.

## Hint

Search kubernetes.io/docs for **"helm show values"** - the Helm CLI reference explains how to
print a chart's default `values.yaml` straight from a local chart directory (or a packaged
chart) without installing a release first.
