#!/usr/bin/env bash
# Stages a local chart with a default value the candidate must go read via
# `helm show values` (not guess, not install-and-inspect) - the chart is
# never installed by setup.sh and has no other consumer.

set -euo pipefail

QUESTION_ID="q110-16-helm-show-values${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
name: lookup
description: A minimal chart for CKAD "helm show values" practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
region: us-east-1
EOF

cat > "$CHART_DIR/templates/configmap.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-lookup
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  region: {{ .Values.region | quote }}
EOF

echo "setup.sh: $QUESTION_ID ready (chart 'lookup' staged, uninstalled, at $CHART_DIR)"
