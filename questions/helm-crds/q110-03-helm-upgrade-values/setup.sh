#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-03-helm-upgrade-values${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
name: webfront
description: A minimal chart for CKAD helm upgrade practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
image:
  repository: nginx
  tag: "1.25-alpine"
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-webfront
  labels:
    app: webfront
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webfront
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: webfront
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: webfront
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
EOF

# Pre-install revision 1 so the candidate's task is the *upgrade*, not the
# initial install.
helm install site "$CHART_DIR" -n "$QUESTION_ID" --wait --timeout 60s >/dev/null

echo "setup.sh: $QUESTION_ID ready (release 'site' at revision 1, chart staged at $CHART_DIR)"
