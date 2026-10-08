#!/usr/bin/env bash
# Failed criteria must not abort the checklist.
set -uo pipefail

QUESTION_ID="q118-05-indexed-job-shards${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# JSON predicates inspect live resources; missing objects/fields fail closed.
json_check() {
  local kind="$1" name="$2" predicate="$3"
  # The selector is supplied by this script, never by the candidate.
  if [[ "$name" == "--all" ]]; then
    kubectl get "$kind" -n "$QUESTION_ID" -o json 2>/dev/null
  elif [[ "$name" == -l* ]]; then
    kubectl get "$kind" -n "$QUESTION_ID" -l "${name#-l }" -o json 2>/dev/null
  else
    kubectl get "$kind" "$name" -n "$QUESTION_ID" -o json 2>/dev/null
  fi | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    passed = bool(eval(sys.argv[1]))
except (ValueError, KeyError, IndexError, TypeError):
    passed = False
sys.exit(0 if passed else 1)
' "$predicate" "$QUESTION_ID"
}

shard_logs() {
  local pods pod output=""
  pods="$(kubectl get pods -n "$QUESTION_ID" -l job-name=shard-worker -o name)" || return 1
  [[ -n "$pods" ]] || return 1
  while IFS= read -r pod; do
    output+="$(kubectl logs "$pod" -n "$QUESTION_ID" 2>/dev/null)"$'\n'
  done <<< "$pods"
  [[ "$(printf '%s' "$output" | sed '/^$/d' | sort)" == $'shard 0: ada,bola\nshard 1: chidi,dayo\nshard 2: emeka,funmi' ]]
}

check_criterion 'shard-worker assigns three indexes and runs three Pods in parallel' \
  json_check job shard-worker '(
    d["spec"]["template"]["spec"]["containers"][0]["image"] == "busybox:1.36"
    and d["spec"]["completionMode"] == "Indexed"
    and d["spec"]["completions"] == 3
    and d["spec"]["parallelism"] == 3
    and d["spec"]["template"]["spec"]["volumes"][0]["configMap"]["name"] == "shards"
  )'
check_criterion "Each shard was processed by its own Pod" shard_logs

print_score
