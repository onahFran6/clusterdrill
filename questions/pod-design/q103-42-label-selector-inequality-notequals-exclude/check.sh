#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-42-label-selector-inequality-notequals-exclude${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Each non-prod pod's positive label is bundled with both prod pods staying
# untouched - "prod pods were not labeled" is already true immediately after
# setup.sh, before the candidate does anything, so as standalone criteria
# those would trivially pass pre-solve.
check_criterion "'svc-dev' is labeled maintenance-window=true, while both prod pods are not" \
  bash -c '
    [ "$(kubectl get pod svc-dev -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.maintenance-window}" 2>/dev/null)" = "true" ] || exit 1
    [ "$(kubectl get pod svc-prod-1 -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.maintenance-window}" 2>/dev/null)" != "true" ] || exit 1
    [ "$(kubectl get pod svc-prod-2 -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.maintenance-window}" 2>/dev/null)" != "true" ]
  '

check_criterion "'svc-staging' is labeled maintenance-window=true, while both prod pods are not" \
  bash -c '
    [ "$(kubectl get pod svc-staging -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.maintenance-window}" 2>/dev/null)" = "true" ] || exit 1
    [ "$(kubectl get pod svc-prod-1 -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.maintenance-window}" 2>/dev/null)" != "true" ] || exit 1
    [ "$(kubectl get pod svc-prod-2 -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.maintenance-window}" 2>/dev/null)" != "true" ]
  '

check_criterion "'svc-canary' is labeled maintenance-window=true, while both prod pods are not" \
  bash -c '
    [ "$(kubectl get pod svc-canary -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.maintenance-window}" 2>/dev/null)" = "true" ] || exit 1
    [ "$(kubectl get pod svc-prod-1 -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.maintenance-window}" 2>/dev/null)" != "true" ] || exit 1
    [ "$(kubectl get pod svc-prod-2 -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.maintenance-window}" 2>/dev/null)" != "true" ]
  '

print_score
