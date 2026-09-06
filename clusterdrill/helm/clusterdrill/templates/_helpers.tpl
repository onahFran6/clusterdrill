{{/*
Recommended labels, fixed-value ones only - matches
clusterdrill/manifests/local-appliance.yaml and
docs/adr/0002-kubernetes-metadata-conventions.md exactly. Every resource
also carries app.kubernetes.io/version (from .Chart.AppVersion) and
app.kubernetes.io/component (varies per resource) - added at each
template's own call site alongside this helper, not baked in here, to
match clusterdrill/tests/test_manifest.py's per-resource expectations.
*/}}
{{- define "clusterdrill.labels" -}}
app.kubernetes.io/name: clusterdrill
app.kubernetes.io/instance: clusterdrill
app.kubernetes.io/part-of: clusterdrill
app.kubernetes.io/managed-by: clusterdrill-cli
{{- end -}}

{{/*
The selector - name+instance only, deliberately excluding version and
component. Both are immutable after the Deployment/Service exist, so
nothing that legitimately changes release to release may be in them -
same reasoning as the raw manifest's own selector comment.
*/}}
{{- define "clusterdrill.selectorLabels" -}}
app.kubernetes.io/name: clusterdrill
app.kubernetes.io/instance: clusterdrill
{{- end -}}
