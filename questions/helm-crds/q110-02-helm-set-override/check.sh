#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-02-helm-set-override${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'ctr-counter' exists in $QUESTION_ID" \
  resource_exists deployment ctr-counter -n "$QUESTION_ID"

check_criterion "Deployment 'ctr-counter' has 3 replicas requested" \
  [ "$(kget deployment ctr-counter '{.spec.replicas}' -n "$QUESTION_ID")" = "3" ]

check_criterion "Deployment 'ctr-counter' has 3 available replicas" \
  [ "$(kget deployment ctr-counter '{.status.availableReplicas}' -n "$QUESTION_ID")" = "3" ]

HELM_VALUES="$(helm get values ctr -n "$QUESTION_ID" -o json 2>/dev/null)"
check_criterion "Release 'ctr' user-supplied values set replicaCount=3" \
  [ "$(echo "$HELM_VALUES" | grep -o '"replicaCount":[0-9]*')" = '"replicaCount":3' ]

print_score
