#!/usr/bin/env bash
# Stages a local chart whose rendered container name the candidate must go
# read via `helm template` (not guess, not install-and-inspect) - the
# chart is never installed by setup.sh and has no other consumer.

set -euo pipefail

QUESTION_ID="q110-18-helm-template-dry-run${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
name: render-only
description: A minimal chart for CKAD "helm template" dry-run practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
replicaCount: 2
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-render-only
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}-render-only
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}-render-only
    spec:
      containers:
        - name: payload-runner
          image: nginx:1.25
EOF

echo "setup.sh: $QUESTION_ID ready (chart 'render-only' staged, uninstalled, at $CHART_DIR)"
