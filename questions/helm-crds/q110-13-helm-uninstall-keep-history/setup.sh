#!/usr/bin/env bash
# Idempotent: creates/resets namespace, seeds a local Helm chart on disk,
# and installs it as release 'demo'. The chart itself is not a Kubernetes
# object, so it needs no clusterdrill label - only the namespace and the
# resources 'helm install' creates need it (the chart's own templates carry
# the label so full_reset can find them).

set -euo pipefail

QUESTION_ID="q110-13-helm-uninstall-keep-history${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
name: widget
description: A minimal chart for CKAD helm uninstall --keep-history practice
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
  name: {{ .Release.Name }}-widget
  labels:
    app: widget
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: widget
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: widget
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: widget
          image: "{{ .Values.image }}"
EOF

# Single release the candidate must uninstall while preserving its history.
helm install demo "$CHART_DIR" -n "$QUESTION_ID" --wait --timeout 60s >/dev/null

echo "setup.sh: $QUESTION_ID ready (release 'demo' installed)"
