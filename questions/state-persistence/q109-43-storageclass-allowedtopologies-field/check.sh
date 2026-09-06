#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-43-storageclass-allowedtopologies-field${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

NODE_NAME="$(kubectl get nodes -o jsonpath='{.items[0].metadata.labels.kubernetes\.io/hostname}')"

check_criterion "StorageClass 'zone-restricted-storage' exists" \
  resource_exists storageclass zone-restricted-storage

check_criterion "StorageClass provisioner is k8s.io/minikube-hostpath, volumeBindingMode WaitForFirstConsumer" \
  bash -c "[ \"\$(kubectl get storageclass zone-restricted-storage -o jsonpath='{.provisioner}')\" = 'k8s.io/minikube-hostpath' ] && \
    [ \"\$(kubectl get storageclass zone-restricted-storage -o jsonpath='{.volumeBindingMode}')\" = 'WaitForFirstConsumer' ]"

check_criterion "allowedTopologies restricts kubernetes.io/hostname to this cluster's real node ($NODE_NAME)" \
  bash -c "[ \"\$(kubectl get storageclass zone-restricted-storage -o jsonpath='{.allowedTopologies[0].matchLabelExpressions[0].key}')\" = 'kubernetes.io/hostname' ] && \
    [ \"\$(kubectl get storageclass zone-restricted-storage -o jsonpath='{.allowedTopologies[0].matchLabelExpressions[0].values[0]}')\" = '$NODE_NAME' ]"

print_score
