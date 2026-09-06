#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-09-custom-storageclass-provisioner${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "StorageClass 'fast-ephemeral' exists" \
  resource_exists storageclass fast-ephemeral

check_criterion "StorageClass labeled clusterdrill-question=$QUESTION_ID" \
  [ "$(kget storageclass fast-ephemeral '{.metadata.labels.clusterdrill-question}')" = "$QUESTION_ID" ]

check_criterion "StorageClass provisioner is k8s.io/minikube-hostpath" \
  [ "$(kget storageclass fast-ephemeral '{.provisioner}')" = "k8s.io/minikube-hostpath" ]

check_criterion "StorageClass reclaimPolicy is Delete" \
  [ "$(kget storageclass fast-ephemeral '{.reclaimPolicy}')" = "Delete" ]

check_criterion "StorageClass volumeBindingMode is Immediate" \
  [ "$(kget storageclass fast-ephemeral '{.volumeBindingMode}')" = "Immediate" ]

sc_exists=0
resource_exists storageclass fast-ephemeral && sc_exists=1
is_default="$(kget storageclass fast-ephemeral '{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}')"
check_criterion "StorageClass 'fast-ephemeral' exists and is not marked default" \
  bash -c '[ "$1" = "1" ] && [ "$2" != "true" ]' _ "$sc_exists" "$is_default"

print_score
