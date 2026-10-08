#!/usr/bin/env bash
# Failed criteria must not abort the checklist.
set -uo pipefail

QUESTION_ID="q118-09-pod-failure-policy-skips-pointless-retries${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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

check_criterion 'validate keeps four retries but fails immediately on exit code three' \
  json_check job validate '(
    d["spec"]["template"]["spec"]["containers"][0]["image"] == "busybox:1.36"
    and d["spec"]["backoffLimit"] == 4
    and d["spec"]["template"]["spec"]["restartPolicy"] == "Never"
    and d["spec"]["podFailurePolicy"]["rules"] == [{"action": "FailJob", "onExitCodes": {"containerName": "validate", "operator": "In", "values": [3]}}]
    and d["spec"]["template"]["spec"]["containers"][0]["command"] == ["sh", "-c", "echo invalid input; exit 3"]
  )'
check_criterion 'validate failed specifically from its Pod failure policy' \
  json_check job validate 'any(c.get("type") == "Failed" and c.get("status") == "True" and c.get("reason") == "PodFailurePolicy" for c in d.get("status", {}).get("conditions", []))'
check_criterion 'validate created one failed attempt' \
  json_check pods '-l job-name=validate' '(
    len(d["items"]) == 1
    and d["items"][0].get("status", {}).get("phase") == "Failed"
  )'

print_score
