#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-27-storageclass-waitforfirstconsumer${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "StorageClass 'delayed-binding' exists" \
  resource_exists storageclass delayed-binding

check_criterion "StorageClass provisioner is k8s.io/minikube-hostpath" \
  [ "$(kget storageclass delayed-binding '{.provisioner}')" = "k8s.io/minikube-hostpath" ]

check_criterion "StorageClass volumeBindingMode is WaitForFirstConsumer" \
  [ "$(kget storageclass delayed-binding '{.volumeBindingMode}')" = "WaitForFirstConsumer" ]

check_criterion "PVC 'delayed-claim' exists" \
  resource_exists pvc delayed-claim -n "$QUESTION_ID"

check_criterion "PVC 'delayed-claim' is Bound" \
  [ "$(kget pvc delayed-claim '{.status.phase}' -n "$QUESTION_ID")" = "Bound" ]

check_criterion "Pod 'consumer' exists" \
  resource_exists pod consumer -n "$QUESTION_ID"

check_criterion "Pod 'consumer' is Running" \
  [ "$(kget pod consumer '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

print_score
