#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-06-helm-get-values${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
name: cache
description: A minimal chart for CKAD helm get values practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
image: redis:7-alpine
maxMemoryMb: 64
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-cache
  labels:
    app: cache
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cache
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: cache
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: cache
          image: "{{ .Values.image }}"
          env:
            - name: MAXMEMORY_MB
              value: "{{ .Values.maxMemoryMb }}"
EOF

# Installed with a non-default override the candidate must go find, not
# guess - this is what makes "helm get values" the actual task instead of
# "read values.yaml on disk."
helm install cache-1 "$CHART_DIR" -n "$QUESTION_ID" --set maxMemoryMb=256 --wait --timeout 60s >/dev/null

echo "setup.sh: $QUESTION_ID ready (release 'cache-1' installed with a non-default maxMemoryMb)"
