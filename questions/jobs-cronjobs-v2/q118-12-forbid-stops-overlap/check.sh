#!/usr/bin/env bash
# Failed criteria must not abort the checklist.
set -uo pipefail

QUESTION_ID="q118-12-forbid-stops-overlap${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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

overlap_stopped() {
  local i
  for ((i=0; i<4; i++)); do
    json_check cronjob sync 'd["spec"].get("concurrencyPolicy") == "Forbid" and not d["spec"].get("suspend", False) and bool(d.get("status", {}).get("lastScheduleTime")) and len(d.get("status", {}).get("active", [])) <= 1' || return 1
    [[ "$i" == 3 ]] || sleep 5
  done
}

check_criterion 'sync skips overlaps while preserving its workload and schedule' \
  json_check cronjob sync '(
    d["spec"]["jobTemplate"]["spec"]["template"]["spec"]["containers"][0]["image"] == "busybox:1.36"
    and d["spec"]["concurrencyPolicy"] == "Forbid"
    and d["spec"]["schedule"] == "*/1 * * * *"
    and d["spec"]["jobTemplate"]["spec"]["template"]["spec"]["containers"][0]["command"] == ["sleep", "150"]
  )'
check_criterion "Scheduled sync has at most one active Job across a settling window" overlap_stopped

print_score
