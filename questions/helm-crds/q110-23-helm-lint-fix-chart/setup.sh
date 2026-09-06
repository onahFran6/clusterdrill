#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a broken local Helm chart
# on disk for the candidate to fix. The chart itself is not a Kubernetes
# object, so it needs no clusterdrill label - only the namespace and
# anything the candidate's `helm install` eventually creates need it (the
# chart's own templates carry the label so full_reset can find them).
#
# Broken on purpose in two ways:
#   1. Chart.yaml has no `version:` field (required by `helm lint`).
#   2. templates/deployment.yaml reads `.Values.image`, but values.yaml only
#      defines `img: nginx:1.25-alpine` - the key mismatch renders an empty
#      image, which `helm lint` also flags.

set -euo pipefail

QUESTION_ID="q110-23-helm-lint-fix-chart${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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

# NOTE: no `version:` field here on purpose - this is the first defect.
cat > "$CHART_DIR/Chart.yaml" <<'EOF'
apiVersion: v2
name: checkup
description: A minimal chart for CKAD helm lint practice (intentionally broken)
appVersion: "1.0"
EOF

# NOTE: key is `img`, but the template below reads `.Values.image` - the
# second defect (mismatched key).
cat > "$CHART_DIR/values.yaml" <<'EOF'
img: nginx:1.25-alpine
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-checkup
  labels:
    app: checkup
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: checkup
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: checkup
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: checkup
          image: {{ .Values.image }}
EOF

echo "setup.sh: $QUESTION_ID ready (broken chart staged at $CHART_DIR)"
