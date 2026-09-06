#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-50-helm-values-schema-json-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
name: worker-pool
description: A minimal chart for CKAD Helm values.schema.json practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
replicaCount: 1
EOF

cat > "$CHART_DIR/values.schema.json" <<'EOF'
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1,
      "maximum": 3
    }
  }
}
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-worker-pool
  labels:
    app: worker-pool
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: worker-pool
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: worker-pool
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: worker-pool
          image: nginx:1.25-alpine
          resources:
            requests:
              cpu: 10m
              memory: 16Mi
            limits:
              cpu: 50m
              memory: 32Mi
EOF

echo "setup.sh: $QUESTION_ID ready (chart staged at $CHART_DIR, values.schema.json caps replicaCount at 3)"
