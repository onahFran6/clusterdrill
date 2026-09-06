#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-40-helm-chart-local-subchart-dependency${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Directory names must match the topic's .gitignore pattern (*/chart*/) so
# these generated-at-runtime chart trees never get committed.
CACHE_DIR="$SCRIPT_DIR/chart-cache"
WEBAPP_DIR="$SCRIPT_DIR/chart"
rm -rf "$CACHE_DIR" "$WEBAPP_DIR"
mkdir -p "$CACHE_DIR/templates" "$WEBAPP_DIR/templates"

cat > "$CACHE_DIR/Chart.yaml" <<'EOF'
apiVersion: v2
name: cache
description: A minimal subchart for CKAD Helm dependency practice
version: 0.1.0
EOF

cat > "$CACHE_DIR/templates/configmap.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-cache
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  ttlSeconds: "300"
EOF

cat > "$WEBAPP_DIR/Chart.yaml" <<'EOF'
apiVersion: v2
name: webapp
description: A minimal parent chart for CKAD Helm dependency practice
version: 0.1.0
appVersion: "1.0"
dependencies:
  - name: cache
    version: 0.1.0
    repository: "file://../chart-cache"
EOF

cat > "$WEBAPP_DIR/values.yaml" <<'EOF'
image: nginx:1.25-alpine
EOF

cat > "$WEBAPP_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-webapp
  labels:
    app: webapp
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: webapp
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: webapp
          image: {{ .Values.image }}
EOF

echo "setup.sh: $QUESTION_ID ready (webapp chart staged at $WEBAPP_DIR, cache subchart at $CACHE_DIR, dependency not yet fetched)"
