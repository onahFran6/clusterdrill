#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-57-helm-get-values-past-revision${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
rm -f "$WORK_DIR/revision4-user.json" "$WORK_DIR/revision4-all.json"

CHART_DIR="$SCRIPT_DIR/chart"
rm -rf "$CHART_DIR"
mkdir -p "$CHART_DIR/templates"

cat > "$CHART_DIR/Chart.yaml" <<'EOF'
apiVersion: v2
name: hotfixapp
description: A minimal chart for CKAD helm get values --revision practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
image: nginx:1.25-alpine
buildTag: v1
region: us-east
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-hotfixapp
  labels:
    app: hotfixapp
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hotfixapp
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: hotfixapp
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: hotfixapp
          image: "{{ .Values.image }}"
          env:
            - name: BUILD_TAG
              value: "{{ .Values.buildTag }}"
            - name: REGION
              value: "{{ .Values.region }}"
EOF

# Revision 1: install with defaults.
helm install app "$CHART_DIR" -n "$QUESTION_ID" --wait --timeout 60s >/dev/null

# Revisions 2-7: only ever override buildTag. Revision 4's value
# (v4-hotfix) is the one the candidate has to dig up; revisions 5-7 move
# past it so the release's *current* state no longer reflects it.
for tag in v2 v3 v4-hotfix v5 v6 v7; do
  helm upgrade app "$CHART_DIR" -n "$QUESTION_ID" --set buildTag="$tag" --wait --timeout 60s >/dev/null
done

echo "setup.sh: $QUESTION_ID ready (release 'app' at revision 7; revision 4 had buildTag=v4-hotfix)"
