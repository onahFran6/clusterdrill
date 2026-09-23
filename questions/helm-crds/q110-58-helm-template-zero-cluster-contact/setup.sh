#!/usr/bin/env bash
# Stages a local chart the candidate must render (not install) via `helm
# template` - the chart is never installed by setup.sh and has no other
# consumer, mirroring q110-18's "render, don't install" shape but paired
# with a workdir output file so check.sh can grade the rendered content
# directly instead of only the absence of cluster resources.

set -euo pipefail

QUESTION_ID="q110-58-helm-template-zero-cluster-contact${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
rm -f "$WORK_DIR/rendered.yaml"

CHART_DIR="$SCRIPT_DIR/chart"
rm -rf "$CHART_DIR"
mkdir -p "$CHART_DIR/templates"

cat > "$CHART_DIR/Chart.yaml" <<'EOF'
apiVersion: v2
name: payloadapp
description: A minimal chart for CKAD "helm template" zero-contact practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
replicaCount: 2
workerImage: busybox:1.36
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-payloadapp
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}-payloadapp
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}-payloadapp
    spec:
      containers:
        - name: worker
          image: "{{ .Values.workerImage }}"
          command: ["sleep", "3600"]
EOF

echo "setup.sh: $QUESTION_ID ready (chart 'payloadapp' staged at $CHART_DIR, uninstalled)"
