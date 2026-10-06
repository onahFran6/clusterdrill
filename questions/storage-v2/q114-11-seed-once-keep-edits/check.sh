#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-11-seed-once-keep-edits${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC site-content requests 100Mi" \
  bash -c '[ "$(kubectl get pvc site-content -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.resources.requests.storage}" 2>/dev/null)" = "100Mi" ]'

check_criterion "Deployment site uses strategy Recreate" \
  bash -c '[ "$(kubectl get deployment site -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.type}" 2>/dev/null)" = "Recreate" ]'

check_criterion "init container seed only copies index.html if it's not already on the claim" \
  bash -c '
    cmd="$(kubectl get deployment site -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.initContainers[?(@.name==\"seed\")].command}" 2>/dev/null)"
    echo "$cmd" | grep -q -- "-f" && echo "$cmd" | grep -q "index.html"
  '

check_criterion "Deployment site is Running" \
  bash -c '[ "$(kubectl get deployment site -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)" = "1" ]'

check_criterion "site now serves the candidate's own hand-edited content (final state only)" \
  bash -c '
    for i in $(seq 1 12); do
      out="$(kubectl exec deploy/site -n "'"$QUESTION_ID"'" -- curl -s localhost 2>/dev/null)"
      [ "$out" = "edited by hand" ] && exit 0
      sleep 5
    done
    exit 1
  '

print_score
