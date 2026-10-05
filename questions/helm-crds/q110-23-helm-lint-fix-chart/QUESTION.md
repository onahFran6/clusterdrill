# q110-23-helm-lint-fix-chart: Fix a Helm chart that fails helm lint before installing

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-23-helm-lint-fix-chart`

A local Helm chart named `checkup` is on disk at
`$HOME/practice-work/q110-23-helm-lint-fix-chart/chart`.
`helm lint` on that chart currently reports errors, and the chart is not yet installed.

Fix the chart files so `helm lint $HOME/practice-work/q110-23-helm-lint-fix-chart/chart`
passes with no errors, then install it into this namespace as release `fixed` using the chart's
own defaults (do not pass `--set`). The resulting Deployment `fixed-checkup` must run container
image `nginx:1.25-alpine`.

## Hint

Search kubernetes.io/docs for **"helm lint"** - `Chart.yaml` requires a non-empty `version`
field, and every `.Values.*` reference in templates must match a key actually defined in
`values.yaml` (a mismatch leaves the rendered image empty). Align the values key with the
template, or the other way around, so the chart renders `nginx:1.25-alpine`.
