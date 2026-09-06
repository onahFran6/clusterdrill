#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-05-helm-list-uninstall${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
name: worker
description: A minimal chart for CKAD helm list/uninstall practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
image: nginx:1.25-alpine
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-worker
  labels:
    app: worker
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: worker
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: worker
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: worker
          image: "{{ .Values.image }}"
EOF

# Two releases in the same namespace - the candidate must remove only one.
helm install worker-a "$CHART_DIR" -n "$QUESTION_ID" --wait --timeout 60s >/dev/null
helm install worker-b "$CHART_DIR" -n "$QUESTION_ID" --wait --timeout 60s >/dev/null

echo "setup.sh: $QUESTION_ID ready (releases 'worker-a' and 'worker-b' installed)"
