#!/usr/bin/env bash
# Failed criteria must not abort the checklist.
set -uo pipefail

QUESTION_ID="q118-04-hard-deadline-beats-retries${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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

check_criterion 'report has the requested image, workload, and Job-level 20-second deadline' \
  json_check job report '(
    d["spec"]["template"]["spec"]["containers"][0]["image"] == "busybox:1.36"
    and d["spec"]["template"]["spec"]["containers"][0]["command"] == ["sleep", "300"]
    and d["spec"]["activeDeadlineSeconds"] == 20
  )'
check_criterion 'report failed because its Job deadline expired' \
  json_check job report 'any(c.get("type") == "Failed" and c.get("status") == "True" and c.get("reason") == "DeadlineExceeded" for c in d.get("status", {}).get("conditions", []))'

print_score
