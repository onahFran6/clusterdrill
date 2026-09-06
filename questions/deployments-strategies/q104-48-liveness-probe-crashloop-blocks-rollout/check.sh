#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-48-liveness-probe-crashloop-blocks-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Container 'session-api' livenessProbe.initialDelaySeconds is 15, other probe fields unchanged" \
  bash -c '
    delay="$(kubectl get deployment session-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].livenessProbe.initialDelaySeconds}" 2>/dev/null)"
    [ "$delay" = "15" ] || exit 1
    period="$(kubectl get deployment session-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].livenessProbe.periodSeconds}" 2>/dev/null)"
    threshold="$(kubectl get deployment session-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].livenessProbe.failureThreshold}" 2>/dev/null)"
    [ "$period" = "2" ] && [ "$threshold" = "1" ]
  '

# Gated on the actual fixed initialDelaySeconds too (not just readiness) -
# with no readinessProbe defined, pod readiness tracks "container running",
# not the liveness outcome, so a pod sampled right after a CrashLoopBackOff
# restart can transiently read Ready even before the real fix (false
# positive / flaky, not deterministic).
check_criterion "Deployment 'session-api' rollout completed: 2 ready, 2 updated" \
  bash -c '
    delay="$(kubectl get deployment session-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].livenessProbe.initialDelaySeconds}" 2>/dev/null)"
    [ "$delay" = "15" ] || exit 1
    ready="$(kubectl get deployment session-api -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment session-api -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ "$ready" = "2" ] && [ "$updated" = "2" ]
  '

check_criterion "Deployment 'session-api' Progressing condition is True, reason NewReplicaSetAvailable" \
  bash -c '
    delay="$(kubectl get deployment session-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].livenessProbe.initialDelaySeconds}" 2>/dev/null)"
    [ "$delay" = "15" ] || exit 1
    status="$(kubectl get deployment session-api -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Progressing\")].status}" 2>/dev/null)"
    reason="$(kubectl get deployment session-api -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Progressing\")].reason}" 2>/dev/null)"
    [ "$status" = "True" ] && [ "$reason" = "NewReplicaSetAvailable" ]
  '

print_score
