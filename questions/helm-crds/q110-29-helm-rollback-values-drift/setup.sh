#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-29-helm-rollback-values-drift${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
name: configurable
description: A minimal chart for CKAD helm rollback practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
mode: stable
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-configurable
  labels:
    app: configurable
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: configurable
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: configurable
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: configurable
          image: nginx:1.25-alpine
          env:
            - name: APP_MODE
              value: "{{ .Values.mode }}"
EOF

cat > "$CHART_DIR/templates/configmap.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configurable-cfg
  labels:
    app: configurable
    clusterdrill-question: $QUESTION_ID
data:
  mode: "{{ .Values.mode }}"
EOF

# Revision 1: original install, mode=stable (chart default).
helm install app "$CHART_DIR" -n "$QUESTION_ID" --wait --timeout 60s >/dev/null

# Revision 2: upgrade to mode=canary.
helm upgrade app "$CHART_DIR" -n "$QUESTION_ID" \
  --set mode=canary --wait --timeout 60s >/dev/null

# Revision 3: upgrade to mode=broken-experimental (current live state).
helm upgrade app "$CHART_DIR" -n "$QUESTION_ID" \
  --set mode=broken-experimental --wait --timeout 60s >/dev/null

echo "setup.sh: $QUESTION_ID ready (release 'app' at revision 3, mode=broken-experimental)"
