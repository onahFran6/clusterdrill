#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-36-scale-via-patch-merge${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# 'session-store' already exists (at 3 replicas) by the time the candidate
# connects, so every criterion is gated on replicas=6, the one thing that
# actually changes.

check_criterion "Deployment 'session-store' has 6 replicas configured and 6 ready" \
  bash -c '
    replicas="$(kubectl get deployment session-store -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    ready="$(kubectl get deployment session-store -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$replicas" = "6" ] && [ "$ready" = "6" ]
  '

check_criterion "Deployment 'session-store' was patched in place, not recreated (image and label unchanged, now at 6 replicas)" \
  bash -c '
    replicas="$(kubectl get deployment session-store -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    image="$(kubectl get deployment session-store -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    label="$(kubectl get deployment session-store -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.metadata.labels.app}" 2>/dev/null)"
    [ "$replicas" = "6" ] && [ "$image" = "memcached:1.6-alpine" ] && [ "$label" = "session-store" ]
  '

print_score
