#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-56-helm-list-all-namespaces-failed-filter${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# question_workdir persists across runs (full_reset only tears down cluster
# state) - clear any stale output files so the unsolved state can't
# accidentally pass on leftover data from a previous attempt.
WORK_DIR="$(question_workdir "$QUESTION_ID")"
rm -f "$WORK_DIR/all-releases.json" "$WORK_DIR/failed-releases.json"

CHART_DIR="$SCRIPT_DIR/chart"
rm -rf "$CHART_DIR"
mkdir -p "$CHART_DIR/templates"

cat > "$CHART_DIR/Chart.yaml" <<'EOF'
apiVersion: v2
name: auditapp
description: A minimal chart for CKAD helm list -A --failed practice
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
  name: {{ .Release.Name }}-auditapp
  labels:
    app: auditapp
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: auditapp
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: auditapp
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: auditapp
          image: "{{ .Values.image }}"
EOF

helm install svc-one "$CHART_DIR" -n "$QUESTION_ID" --wait --timeout 60s >/dev/null
helm install svc-two "$CHART_DIR" -n "$QUESTION_ID" --wait --timeout 60s >/dev/null

# svc-three: install cleanly, then a bad upgrade (no --atomic) that fails
# and is left status=failed, no auto-rollback, for the --failed filter to
# actually have something to find.
helm install svc-three "$CHART_DIR" -n "$QUESTION_ID" --wait --timeout 60s >/dev/null
helm upgrade svc-three "$CHART_DIR" -n "$QUESTION_ID" \
  --set image=nginx:this-tag-does-not-exist --wait --timeout 20s >/dev/null 2>&1 || true

echo "setup.sh: $QUESTION_ID ready (svc-one/svc-two deployed, svc-three failed)"
