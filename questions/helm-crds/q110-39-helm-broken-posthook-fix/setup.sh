#!/usr/bin/env bash
# Stages a local Helm chart whose post-install hook Job is broken on
# purpose (its container execs `exit 1`), then actually runs `helm install`
# against it - unlike a broken pre-install hook, this fails only AFTER the
# chart's other resources (the Deployment) are already applied, leaving a
# real release object behind marked `failed` rather than no release at
# all. The candidate must fix the Job's command on disk, then `helm
# upgrade` the existing release forward to `deployed`.
set -euo pipefail

QUESTION_ID="q110-39-helm-broken-posthook-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
name: notifier
description: A minimal chart with a broken post-install hook, for CKAD Helm hooks practice
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
  name: {{ .Release.Name }}-notifier
  labels:
    app: notifier
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: notifier
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: notifier
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: notifier
          image: {{ .Values.image }}
EOF

# NOTE: the command deliberately exits 1 - the defect the candidate must
# fix. The hook annotations must stay intact after the fix.
cat > "$CHART_DIR/templates/posthook.yaml" <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-notifier-posthook
  labels:
    app: notifier
    clusterdrill-question: $QUESTION_ID
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        app: notifier
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      containers:
        - name: post-install-notify
          image: busybox:1.36
          command: ["sh", "-c", "exit 1"]
EOF

helm install demo "$CHART_DIR" -n "$QUESTION_ID" --timeout 30s || true

echo "setup.sh: $QUESTION_ID ready (release 'demo' exists but failed - post-install hook is broken)"
