#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-21-helm-multiple-value-files${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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

OVERRIDES_DIR="$SCRIPT_DIR/overrides"
rm -rf "$OVERRIDES_DIR"
mkdir -p "$OVERRIDES_DIR"

cat > "$CHART_DIR/Chart.yaml" <<'EOF'
apiVersion: v2
name: stacker
description: A minimal chart for CKAD helm multi-values-file practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
image: nginx:1.25-alpine
replicaCount: 1
envTier: dev
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-stacker
  labels:
    app: stacker
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: stacker
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: stacker
        release: {{ .Release.Name }}
        tier: {{ .Values.envTier }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: stacker
          image: "{{ .Values.image }}"
EOF

# Sibling override file - deliberately OUTSIDE the chart directory, so the
# candidate must pass it explicitly with -f rather than it being picked up
# automatically the way a chart's own values.yaml is.
cat > "$OVERRIDES_DIR/prod-values.yaml" <<'EOF'
replicaCount: 3
envTier: prod
EOF

echo "setup.sh: $QUESTION_ID ready (chart 'stacker' staged at $CHART_DIR, overrides at $OVERRIDES_DIR/prod-values.yaml)"
