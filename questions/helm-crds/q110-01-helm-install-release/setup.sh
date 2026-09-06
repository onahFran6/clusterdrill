#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a local Helm chart on disk
# for the candidate to install. The chart itself is not a Kubernetes object,
# so it needs no clusterdrill label - only the namespace and anything the
# candidate's `helm install` eventually creates need it (the chart's own
# templates carry the label so full_reset can find them).

set -euo pipefail

QUESTION_ID="q110-01-helm-install-release${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
name: greeter
description: A minimal chart for CKAD Helm practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
image: nginx:1.25-alpine
replicaCount: 1
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-greeter
  labels:
    app: greeter
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: greeter
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: greeter
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: greeter
          image: {{ .Values.image }}
EOF

echo "setup.sh: $QUESTION_ID ready (chart staged at $CHART_DIR)"
