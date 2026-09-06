#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a local Helm chart on disk
# for the candidate to converge with `helm upgrade --install`. The chart
# itself is not a Kubernetes object, so it needs no clusterdrill label -
# only the namespace and anything the candidate's helm command eventually
# creates need it (the chart's own templates carry the label so full_reset
# can find them). No release is pre-installed - the namespace starts with
# zero Helm releases.

set -euo pipefail

QUESTION_ID="q110-19-helm-upgrade-install-idempotent${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
name: toggle
description: A minimal chart for CKAD helm upgrade --install practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
featureFlag: "off"
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-toggle
  labels:
    app: toggle
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: toggle
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: toggle
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: toggle
          image: nginx:1.25-alpine
          env:
            - name: FEATURE_FLAG
              value: "{{ .Values.featureFlag }}"
EOF

cat > "$CHART_DIR/templates/configmap.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-toggle-cm
  labels:
    app: toggle
    clusterdrill-question: $QUESTION_ID
data:
  flag: "{{ .Values.featureFlag }}"
EOF

echo "setup.sh: $QUESTION_ID ready (chart staged at $CHART_DIR, no release installed yet)"
