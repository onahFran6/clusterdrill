#!/usr/bin/env bash
# Packages two versions of the same chart (1.0.0 and 2.0.0) as local .tgz
# archives and leaves both on disk, uninstalled - the candidate must pick
# the pinned 1.0.0 package deliberately, not whichever one is newest.
# A real chart-repo `--version` flow (helm repo add/update against an
# index) was deliberately not used here: this bank's grading environment
# has no guarantee a "file://" or bare-path repo getter is available, so
# picking the right packaged archive is the reliable, dependency-free way
# to exercise the same "pin an exact version" skill.

set -euo pipefail

QUESTION_ID="q110-52-helm-install-pinned-version-new-namespace${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CHART_V1="$SCRIPT_DIR/chart-v1"
CHART_V2="$SCRIPT_DIR/chart-v2"
PKG_DIR="$SCRIPT_DIR/chart-pkgs"
rm -rf "$CHART_V1" "$CHART_V2" "$PKG_DIR"
mkdir -p "$CHART_V1/templates" "$CHART_V2/templates" "$PKG_DIR"

cat > "$CHART_V1/Chart.yaml" <<'EOF'
apiVersion: v2
name: cache
description: A minimal chart for CKAD Helm pinned-version practice (v1)
version: 1.0.0
appVersion: "7.2"
EOF

cat > "$CHART_V1/values.yaml" <<'EOF'
image: redis:7.2-alpine
EOF

cat > "$CHART_V1/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-cache
  labels:
    app: cache
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cache
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: cache
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: cache
          image: "{{ .Values.image }}"
EOF

cat > "$CHART_V2/Chart.yaml" <<'EOF'
apiVersion: v2
name: cache
description: A minimal chart for CKAD Helm pinned-version practice (v2)
version: 2.0.0
appVersion: "7.4"
EOF

cat > "$CHART_V2/values.yaml" <<'EOF'
image: redis:7.4-alpine
EOF

cat > "$CHART_V2/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-cache
  labels:
    app: cache
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cache
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: cache
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: cache
          image: "{{ .Values.image }}"
EOF

helm package "$CHART_V1" -d "$PKG_DIR" >/dev/null
helm package "$CHART_V2" -d "$PKG_DIR" >/dev/null

echo "setup.sh: $QUESTION_ID ready (cache-1.0.0.tgz and cache-2.0.0.tgz staged at $PKG_DIR, neither installed)"
