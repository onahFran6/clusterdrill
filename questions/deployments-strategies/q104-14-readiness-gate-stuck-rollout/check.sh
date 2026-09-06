#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-14-readiness-gate-stuck-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'diagnosis' exists in $QUESTION_ID" \
  resource_exists configmap diagnosis -n "$QUESTION_ID"

check_criterion "ConfigMap 'diagnosis' key progressing-status matches the Deployment's actual Progressing condition" \
  bash -c '
    actual="$(kubectl get deployment inventory -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Progressing\")].status}" 2>/dev/null)"
    recorded="$(kubectl get configmap diagnosis -n "'"$QUESTION_ID"'" -o jsonpath="{.data.progressing-status}" 2>/dev/null)"
    [ -n "$actual" ] && [ "$recorded" = "$actual" ]
  '

check_criterion "The recorded status reflects a stalled rollout (False), and the probe was left untouched" \
  bash -c '
    recorded="$(kubectl get configmap diagnosis -n "'"$QUESTION_ID"'" -o jsonpath="{.data.progressing-status}" 2>/dev/null)"
    image="$(kubectl get deployment inventory -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$recorded" = "False" ] && [ "$image" = "nginx:1.25-alpine" ]
  '

print_score
