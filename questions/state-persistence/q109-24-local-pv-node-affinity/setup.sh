#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q109-24-local-pv-node-affinity${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# A `local` PersistentVolume (unlike hostPath) requires the directory to
# already exist on the node - Kubernetes will not create it on demand. Use
# a short-lived privileged pod (portable across whatever driver backs the
# node - docker, VM, bare metal - instead of assuming host/docker access)
# to create it, then delete the pod so it doesn't linger as a leftover
# resource.
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${QUESTION_ID}-mkdir
  namespace: $QUESTION_ID
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  restartPolicy: Never
  containers:
    - name: mkdir
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /mnt/ckad-local-data && chmod 777 /mnt/ckad-local-data"]
      volumeMounts:
        - name: hostmnt
          mountPath: /mnt
  volumes:
    - name: hostmnt
      hostPath:
        path: /mnt
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Succeeded "pod/${QUESTION_ID}-mkdir" \
  --namespace="$QUESTION_ID" --timeout=60s
kubectl delete pod "${QUESTION_ID}-mkdir" --namespace="$QUESTION_ID" --ignore-not-found

echo "setup.sh: $QUESTION_ID ready"
