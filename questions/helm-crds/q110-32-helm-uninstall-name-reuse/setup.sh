#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-32-helm-uninstall-name-reuse${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: {{ .Release.Name }}-widget
  labels:
    app: widget
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: {{ .Values.replicaCount }}
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
          image: {{ .Values.image }}
EOF

# No --wait: busybox with no command crash-loops immediately (only its
# image field matters here as a marker value the candidate's real
# reinstall, using chart defaults, must NOT still show afterward).
helm install demo "$CHART_DIR" -n "$QUESTION_ID" --set image=busybox:1.36

echo "setup.sh: $QUESTION_ID ready (release 'demo' installed; chart staged at $CHART_DIR)"
