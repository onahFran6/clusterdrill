#!/usr/bin/env bash
# Stages two on-disk chart versions (both named 'engine') and pre-installs
# release 'core' from chart-v1 at revision 1. The candidate's task is to
# helm-upgrade 'core' in place onto chart-v2 without a second release name
# or a duplicate Deployment appearing.
set -euo pipefail

QUESTION_ID="q110-27-helm-release-name-collision-namespace${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CHART_V1_DIR="$SCRIPT_DIR/chart-v1"
CHART_V2_DIR="$SCRIPT_DIR/chart-v2"
rm -rf "$CHART_V1_DIR" "$CHART_V2_DIR"
mkdir -p "$CHART_V1_DIR/templates" "$CHART_V2_DIR/templates"

# --- chart-v1 (version 1.0.0) ---
cat > "$CHART_V1_DIR/Chart.yaml" <<'EOF'
apiVersion: v2
name: engine
description: A minimal chart for CKAD helm upgrade practice (v1)
version: 1.0.0
appVersion: "1.0"
EOF

cat > "$CHART_V1_DIR/values.yaml" <<'EOF'
image: nginx:1.25-alpine
EOF

cat > "$CHART_V1_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-engine
  labels:
    app: engine
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: engine
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: engine
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: engine
          image: "{{ .Values.image }}"
          ports:
            - containerPort: 80
EOF

# --- chart-v2 (version 2.0.0) - adds containerPort 8443 and env PROTOCOL=https ---
cat > "$CHART_V2_DIR/Chart.yaml" <<'EOF'
apiVersion: v2
name: engine
description: A minimal chart for CKAD helm upgrade practice (v2)
version: 2.0.0
appVersion: "2.0"
EOF

cat > "$CHART_V2_DIR/values.yaml" <<'EOF'
image: nginx:1.25-alpine
EOF

cat > "$CHART_V2_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-engine
  labels:
    app: engine
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: engine
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: engine
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: engine
          image: "{{ .Values.image }}"
          ports:
            - containerPort: 80
            - containerPort: 8443
          env:
            - name: PROTOCOL
              value: "https"
EOF

# Pre-install revision 1 from chart-v1 so the candidate's task is the
# in-place upgrade onto chart-v2, not the initial install.
helm install core "$CHART_V1_DIR" -n "$QUESTION_ID" --wait --timeout 60s >/dev/null

echo "setup.sh: $QUESTION_ID ready (release 'core' at revision 1 from chart-v1 1.0.0; chart-v2 2.0.0 staged at $CHART_V2_DIR)"
