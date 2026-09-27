# q110-51-helm-named-template-label-fix: Fix a shared named template so its labels reach every resource that includes it

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-51-helm-named-template-label-fix`

A local Helm chart named `webapp` is on disk at
`questions/helm-crds/q110-51-helm-named-template-label-fix/chart` (relative to
`practice-bank/`). `templates/_helpers.tpl` defines a named template `webapp.labels`, and both
`templates/deployment.yaml` and `templates/configmap.yaml` set `metadata.labels` via
`{{ include "webapp.labels" . }}`. Neither resource currently gets an
`app.kubernetes.io/version` label.

Fix `templates/_helpers.tpl` so `webapp.labels` emits
`app.kubernetes.io/version: {{ .Chart.AppVersion }}`, then install the chart into this namespace
as release `demo`. The label must appear on both Deployment `demo-webapp` and ConfigMap
`demo-config` (`Chart.yaml` sets `appVersion: "2.3.1"`).

## Hint

Search kubernetes.io/docs or helm.sh/docs for **"helm named templates"** - the Helm Chart
Template Guide's "Named Templates" page shows a `_helpers.tpl` file with a `{{- define
"name" -}}` block and the `{{ include "name" . }}` call other templates use to reuse it.
