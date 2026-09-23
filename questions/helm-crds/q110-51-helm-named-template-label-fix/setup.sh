#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-51-helm-named-template-label-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Directory name must match the topic's .gitignore pattern (*/chart*/) so
# this generated-at-runtime chart tree never gets committed.
CHART_DIR="$SCRIPT_DIR/chart"
rm -rf "$CHART_DIR"
mkdir -p "$CHART_DIR/templates"

cat > "$CHART_DIR/Chart.yaml" <<'EOF'
apiVersion: v2
name: webapp
description: A minimal chart for CKAD Helm named-template practice
version: 0.1.0
appVersion: "2.3.1"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
image: nginx:1.25-alpine
EOF

# Broken on purpose: the shared named template only emits
# app.kubernetes.io/name and app.kubernetes.io/instance, never
# app.kubernetes.io/version - every template below already calls this
# block via `include`, so fixing it here is the only fix needed.
cat > "$CHART_DIR/templates/_helpers.tpl" <<'EOF'
{{/*
Common labels shared by every resource in this chart.
*/}}
{{- define "webapp.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-webapp
  labels:
    {{- include "webapp.labels" . | nindent 4 }}
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: webapp
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: webapp
          image: {{ .Values.image }}
EOF

cat > "$CHART_DIR/templates/configmap.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-config
  labels:
    {{- include "webapp.labels" . | nindent 4 }}
    clusterdrill-question: $QUESTION_ID
data:
  greeting: "hello"
EOF

echo "setup.sh: $QUESTION_ID ready (webapp chart staged at $CHART_DIR, _helpers.tpl missing app.kubernetes.io/version)"
