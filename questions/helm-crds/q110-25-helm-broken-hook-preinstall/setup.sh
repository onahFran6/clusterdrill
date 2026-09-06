#!/usr/bin/env bash
# Stages a local Helm chart whose pre-install hook Job is broken on purpose
# (its container execs `exit 1`). Helm runs pre-install hooks before any
# other template in the chart, and a hook Job must complete successfully or
# the whole `helm install` aborts - so no release exists yet: a prior
# install attempt against this chart as-is would have failed and left no
# release behind. The candidate must fix the Job's command on disk, then
# install successfully.

set -euo pipefail

QUESTION_ID="q110-25-helm-broken-hook-preinstall${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
name: gatekeeper
description: A minimal chart with a broken pre-install hook, for CKAD Helm hooks practice
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
  name: {{ .Release.Name }}-gatekeeper
  labels:
    app: gatekeeper
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gatekeeper
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: gatekeeper
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: gatekeeper
          image: {{ .Values.image }}
EOF

# NOTE: the command deliberately exits 1 - the defect the candidate must
# fix. The hook annotations (pre-install + before-hook-creation delete
# policy) must stay intact after the fix.
cat > "$CHART_DIR/templates/pre-install-job.yaml" <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-gatekeeper-pre-install
  labels:
    app: gatekeeper
    clusterdrill-question: $QUESTION_ID
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        app: gatekeeper
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      containers:
        - name: pre-install-check
          image: busybox:1.36
          command: ["sh", "-c", "exit 1"]
EOF

echo "setup.sh: $QUESTION_ID ready (chart with broken pre-install hook staged at $CHART_DIR, no release installed)"
