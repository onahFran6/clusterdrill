#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-33-scale-deployment-imperative${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# 'payments-api' already exists (at 2 replicas) by the time the candidate
# connects, so a standalone "exists" criterion would trivially pass before
# any scaling happens - every criterion here is gated on replicas=5
# instead, the one thing that actually changes.

check_criterion "Deployment 'payments-api' has 5 replicas configured and 5 ready" \
  bash -c '
    replicas="$(kubectl get deployment payments-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    ready="$(kubectl get deployment payments-api -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$replicas" = "5" ] && [ "$ready" = "5" ]
  '

check_criterion "Deployment 'payments-api' was scaled in place, not recreated (image nginx:1.25-alpine and label app=payments-api unchanged, now at 5 replicas)" \
  bash -c '
    replicas="$(kubectl get deployment payments-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    image="$(kubectl get deployment payments-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    label="$(kubectl get deployment payments-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.metadata.labels.app}" 2>/dev/null)"
    [ "$replicas" = "5" ] && [ "$image" = "nginx:1.25-alpine" ] && [ "$label" = "payments-api" ]
  '

print_score
