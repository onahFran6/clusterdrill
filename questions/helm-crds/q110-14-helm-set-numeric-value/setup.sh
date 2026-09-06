#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-14-helm-set-numeric-value${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
name: scaler
description: A minimal chart for CKAD Helm --set numeric value practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
replicaCount: 1
image: nginx:1.25-alpine
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-scaler
  labels:
    app: scaler
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: scaler
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: scaler
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: scaler
          image: {{ .Values.image }}
EOF

echo "setup.sh: $QUESTION_ID ready (chart staged at $CHART_DIR)"
