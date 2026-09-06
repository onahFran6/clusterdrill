#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-33-helm-set-string-flag${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
name: flagger
description: A minimal chart for CKAD Helm practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
legacyMode: false
EOF

cat > "$CHART_DIR/templates/configmap.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-flagger
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  status: {{ if .Values.legacyMode }}enabled{{ else }}disabled{{ end }}
EOF

echo "setup.sh: $QUESTION_ID ready (chart staged at $CHART_DIR)"
