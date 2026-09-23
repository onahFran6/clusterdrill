#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-60-helm-values-precedence-three-way${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CHART_DIR="$SCRIPT_DIR/chart"
VALUES_DIR="$SCRIPT_DIR/chart-values"
rm -rf "$CHART_DIR" "$VALUES_DIR"
mkdir -p "$CHART_DIR/templates" "$VALUES_DIR"

cat > "$CHART_DIR/Chart.yaml" <<'EOF'
apiVersion: v2
name: threeway
description: A minimal chart for CKAD -f / --set / --set-string precedence practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
replicaCount: 1
extra:
  featureFlag: "off"
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-threeway
  labels:
    app: threeway
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: threeway
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: threeway
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: threeway
          image: nginx:1.25-alpine
EOF

# extra.featureFlag is rendered through toYaml (not a bare interpolation
# and not piped through `quote`), same technique as q110-53: whether --set
# or --set-string wins actually changes the emitted YAML type. A bool
# lands unquoted (invalid for ConfigMap.data, so the whole release fails
# to install); the --set-string-won string lands quoted (installs fine).
cat > "$CHART_DIR/templates/configmap.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-threeway-extra
  labels:
    clusterdrill-question: $QUESTION_ID
data:
{{ toYaml .Values.extra | indent 2 }}
EOF

cat > "$VALUES_DIR/override-values.yaml" <<'EOF'
replicaCount: 3
EOF

echo "setup.sh: $QUESTION_ID ready (chart 'threeway' staged at $CHART_DIR, override-values.yaml staged at $VALUES_DIR, uninstalled)"
