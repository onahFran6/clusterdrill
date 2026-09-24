#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a local Helm chart on disk
# for the candidate to install with a stack of --set/--set-string flags.
# The chart itself is not a Kubernetes object, so it needs no clusterdrill
# label - only the namespace and anything the candidate's `helm install`
# eventually creates need it (the chart's own templates carry the label).

set -euo pipefail

QUESTION_ID="q110-53-helm-set-nested-and-set-string${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CHART_DIR="$SCRIPT_DIR/chart"
rm -rf "$CHART_DIR"
mkdir -p "$CHART_DIR/templates"

cat > "$CHART_DIR/Chart.yaml" <<'EOF'
apiVersion: v2
name: web
description: A minimal chart for CKAD Helm nested --set / --set-string practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
ingress:
  enabled: false
  hosts:
    - host: chart-example.local
resources:
  limits:
    cpu: 100m
extra:
  buildFlag: "stable"
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-web
  labels:
    app: web
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: web
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: web
          image: nginx:1.25-alpine
          resources:
            limits:
              cpu: {{ .Values.resources.limits.cpu | quote }}
EOF

cat > "$CHART_DIR/templates/service.yaml" <<EOF
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-web
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: web
    release: {{ .Release.Name }}
  ports:
    - port: 80
      targetPort: 80
EOF

cat > "$CHART_DIR/templates/ingress.yaml" <<EOF
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-web
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  rules:
    - host: {{ (first .Values.ingress.hosts).host | quote }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ .Release.Name }}-web
                port:
                  number: 80
{{- end }}
EOF

# extra.buildFlag is rendered through toYaml (not a bare {{ .Values... }}
# interpolation, and not piped through `quote`) so that whether --set or
# --set-string was used on the CLI actually changes the emitted YAML type:
# plain --set buildFlag=true stores a Go bool, which toYaml renders as an
# unquoted `true` - invalid for ConfigMap.data (map[string]string), so the
# whole release fails to install. --set-string keeps it the Go string
# "true", which toYaml quotes, so it installs cleanly.
cat > "$CHART_DIR/templates/configmap.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-web-extra
  labels:
    clusterdrill-question: $QUESTION_ID
data:
{{ toYaml .Values.extra | indent 2 }}
EOF

echo "setup.sh: $QUESTION_ID ready (chart 'web' staged at $CHART_DIR, uninstalled)"
