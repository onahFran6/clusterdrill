#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-04-helm-rollback-release${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
name: api
description: A minimal chart for CKAD helm rollback practice
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
  name: {{ .Release.Name }}-api
  labels:
    app: api
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: api
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: api
          image: "{{ .Values.image }}"
EOF

# Revision 1: working image.
helm install svc "$CHART_DIR" -n "$QUESTION_ID" --wait --timeout 60s >/dev/null

# Revision 2: a bad upgrade to a non-existent image tag, simulating a
# botched deploy the candidate needs to roll back.
helm upgrade svc "$CHART_DIR" -n "$QUESTION_ID" \
  --set image=nginx:does-not-exist-tag --wait --timeout 20s >/dev/null 2>&1 || true

echo "setup.sh: $QUESTION_ID ready (release 'svc' at revision 2, broken image)"
