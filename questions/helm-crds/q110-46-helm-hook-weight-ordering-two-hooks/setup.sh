#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-46-helm-hook-weight-ordering-two-hooks${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# The two hook Jobs below share a hostPath directory to prove execution
# order across separate Pods (a file written by one Job's Pod is otherwise
# invisible to the other's). That directory lives on the node, outside
# Kubernetes, so full_reset never touches it - clear any stale marker file
# left by a previous run of this question first, or a leftover marker
# would make even the WRONG hook order pass by accident.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: clean-helper
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  restartPolicy: Never
  containers:
    - name: clean-helper
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /work && rm -f /work/seed-marker"]
      volumeMounts:
        - name: work
          mountPath: /work
  volumes:
    - name: work
      hostPath:
        path: /tmp/ckad-q110-46-hookdata
        type: DirectoryOrCreate
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/clean-helper -n "$QUESTION_ID" --timeout=60s
kubectl delete pod clean-helper -n "$QUESTION_ID" --wait=true

CHART_DIR="$SCRIPT_DIR/chart"
rm -rf "$CHART_DIR"
mkdir -p "$CHART_DIR/templates"

cat > "$CHART_DIR/Chart.yaml" <<'EOF'
apiVersion: v2
name: seeder
description: A minimal chart with two mis-ordered pre-install hooks, for CKAD Helm hook-weight practice
version: 0.1.0
appVersion: "1.0"
EOF

# NOTE: the weights are deliberately swapped - the defect the candidate
# must fix. verify-data (weight 5) currently runs BEFORE seed-data
# (weight 10), so it never finds the marker file and fails.
cat > "$CHART_DIR/templates/hook-seed.yaml" <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-seed-data
  labels:
    clusterdrill-question: $QUESTION_ID
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-weight": "10"
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      containers:
        - name: seed
          image: busybox:1.36
          command: ["sh", "-c", "echo ready > /work/seed-marker"]
          volumeMounts:
            - name: work
              mountPath: /work
      volumes:
        - name: work
          hostPath:
            path: /tmp/ckad-q110-46-hookdata
            type: DirectoryOrCreate
EOF

cat > "$CHART_DIR/templates/hook-verify.yaml" <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-verify-data
  labels:
    clusterdrill-question: $QUESTION_ID
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-weight": "5"
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      containers:
        - name: verify
          image: busybox:1.36
          command: ["sh", "-c", "test -f /work/seed-marker || exit 1"]
          volumeMounts:
            - name: work
              mountPath: /work
      volumes:
        - name: work
          hostPath:
            path: /tmp/ckad-q110-46-hookdata
            type: DirectoryOrCreate
EOF

echo "setup.sh: $QUESTION_ID ready (chart with mis-ordered hook weights staged at $CHART_DIR, no release installed)"
