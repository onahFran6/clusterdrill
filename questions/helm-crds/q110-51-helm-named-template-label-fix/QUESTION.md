# q110-51-helm-named-template-label-fix: Fix a shared named template so its labels reach every resource that includes it

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-51-helm-named-template-label-fix`

`setup.sh` staged a chart named `webapp` at
`questions/helm-crds/q110-51-helm-named-template-label-fix/chart`. Its `templates/_helpers.tpl`
defines one named template, `webapp.labels`, and both `templates/deployment.yaml` and
`templates/configmap.yaml` render their `metadata.labels` by calling
`{{ include "webapp.labels" . }}` - a single shared block, not labels written out twice.

The named template is incomplete: it does not emit an `app.kubernetes.io/version` label at all,
so neither resource gets one. Fix `templates/_helpers.tpl` so `webapp.labels` adds
`app.kubernetes.io/version: {{ .Chart.AppVersion }}` to its output, then install the chart into
namespace `q110-51-helm-named-template-label-fix` under release name `demo`. Because both
templates already call the shared block, fixing it in one place must make the label show up on
**both** the Deployment (`demo-webapp`) and the ConfigMap (`demo-config`) - `Chart.yaml` sets
`appVersion: "2.3.1"`.

## Hint

Search kubernetes.io/docs or helm.sh/docs for **"helm named templates"** - the Helm Chart
Template Guide's "Named Templates" page shows a `_helpers.tpl` file with a `{{- define
"name" -}}` block and the `{{ include "name" . }}` call other templates use to reuse it.
