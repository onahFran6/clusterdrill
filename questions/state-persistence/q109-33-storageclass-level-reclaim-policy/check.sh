#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-33-storageclass-level-reclaim-policy${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "StorageClass 'compliance-storage' exists" \
  resource_exists storageclass compliance-storage

check_criterion "StorageClass labeled clusterdrill-question=$QUESTION_ID" \
  [ "$(kget storageclass compliance-storage '{.metadata.labels.clusterdrill-question}')" = "$QUESTION_ID" ]

check_criterion "StorageClass provisioner is k8s.io/minikube-hostpath" \
  [ "$(kget storageclass compliance-storage '{.provisioner}')" = "k8s.io/minikube-hostpath" ]

check_criterion "StorageClass reclaimPolicy is Retain" \
  [ "$(kget storageclass compliance-storage '{.reclaimPolicy}')" = "Retain" ]

check_criterion "StorageClass volumeBindingMode is Immediate" \
  [ "$(kget storageclass compliance-storage '{.volumeBindingMode}')" = "Immediate" ]

sc_exists=0
resource_exists storageclass compliance-storage && sc_exists=1
is_default="$(kget storageclass compliance-storage '{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}')"
check_criterion "StorageClass 'compliance-storage' exists and is not marked default" \
  bash -c '[ "$1" = "1" ] && [ "$2" != "true" ]' _ "$sc_exists" "$is_default"

print_score
