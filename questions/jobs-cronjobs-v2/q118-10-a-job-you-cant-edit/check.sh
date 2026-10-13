#!/usr/bin/env bash
# Failed criteria must not abort the checklist.
set -uo pipefail

QUESTION_ID="q118-10-a-job-you-cant-edit${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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

log_check() {
  local resource="$1" pattern="$2" container_name="${3:-}"
  local args=()
  [[ -z "$container_name" ]] || args=(-c "$container_name")
  kubectl logs "$resource" -n "$QUESTION_ID" "${args[@]}" 2>/dev/null |
    python3 -c 'import re, sys; sys.exit(0 if re.search(sys.argv[1], sys.stdin.read(), re.M) else 1)' "$pattern"
}

check_criterion 'export uses the corrected image, preserves its command, and is resumed' \
  json_check job export '(
    d["spec"]["template"]["spec"]["containers"][0]["image"] == "busybox:1.36"
    and d["spec"]["template"]["spec"]["containers"][0]["command"] == ["echo", "exporting"]
    and d["spec"]["suspend"] is False
  )'
check_criterion 'export completed once' \
  json_check job export 'd.get("status", {}).get("succeeded", 0) == 1'
check_criterion 'export logs successful work' log_check job/export '^exporting\s*$' ''

print_score
