# q110-51-helm-named-template-label-fix: reference solution

Doc: https://helm.sh/docs/chart_template_guide/named_templates/

Edit `templates/_helpers.tpl` so the `webapp.labels` block also emits
`app.kubernetes.io/version`, then install:

```sh
CHART=questions/helm-crds/q110-51-helm-named-template-label-fix/chart

cat > "$CHART/templates/_helpers.tpl" <<'EOF'
{{/*
Common labels shared by every resource in this chart.
*/}}
{{- define "webapp.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
{{- end -}}
EOF

helm install demo "$CHART" -n q110-51-helm-named-template-label-fix --wait
```

Both `demo-webapp` (the Deployment) and `demo-config` (the ConfigMap) pick up
`app.kubernetes.io/version: "2.3.1"` from the single fixed block, since both templates already
call `{{ include "webapp.labels" . }}`.
