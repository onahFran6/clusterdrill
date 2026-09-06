#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q109-36-fix-hostpath-type-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# setup.sh only has kubectl access, not a shell on the node itself, so the
# real directory this question's bug depends on is provisioned by running a
# short-lived helper Pod whose hostPath volume uses type DirectoryOrCreate
# (which the kubelet creates on the node before starting the container) -
# the directory outlives the helper Pod once it's deleted, since hostPath
# storage lives on the node, not in the Pod.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: provision-helper
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  restartPolicy: Never
  containers:
    - name: provision-helper
      image: busybox:1.36
      command: ["true"]
      volumeMounts:
        - name: logs
          mountPath: /mnt/q109-36-logs
  volumes:
    - name: logs
      hostPath:
        path: /mnt/q109-36-logs
        type: DirectoryOrCreate
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/provision-helper -n "$QUESTION_ID" --timeout=60s || true
kubectl delete pod provision-helper -n "$QUESTION_ID" --wait=true

# Now the bug: log-writer's hostPath type is File, but /mnt/q109-36-logs (as
# provisioned above) is a real directory - the kubelet's mount-time type
# check rejects the mismatch and the container never starts.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: log-writer
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: log-writer
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: logs
          mountPath: /var/log/app
  volumes:
    - name: logs
      hostPath:
        path: /mnt/q109-36-logs
        type: File
EOF

echo "setup.sh: $QUESTION_ID ready"
