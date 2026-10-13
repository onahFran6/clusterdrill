#!/usr/bin/env bash
# Failed criteria must not abort the checklist.
set -uo pipefail

QUESTION_ID="q118-13-history-limits${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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

history_thinned() {
  local i
  json_check cronjob ping 'd["spec"].get("successfulJobsHistoryLimit") == 2 and d["spec"].get("failedJobsHistoryLimit") == 1 and not d["spec"].get("suspend", False)' || return 1
  for ((i=0; i<15; i++)); do
    if json_check jobs --all 'len([j for j in d["items"] if any(o.get("kind") == "CronJob" and o.get("name") == "ping" for o in j["metadata"].get("ownerReferences", [])) and any(c.get("type") == "Complete" and c.get("status") == "True" for c in j.get("status", {}).get("conditions", []))]) == 2'; then
      return 0
    fi
    sleep 2
  done
  return 1
}

check_criterion 'ping keeps two successful and one failed run with its workload unchanged' \
  json_check cronjob ping '(
    d["spec"]["jobTemplate"]["spec"]["template"]["spec"]["containers"][0]["image"] == "busybox:1.36"
    and d["spec"]["successfulJobsHistoryLimit"] == 2
    and d["spec"]["failedJobsHistoryLimit"] == 1
    and d["spec"]["schedule"] == "*/1 * * * *"
    and d["spec"]["jobTemplate"]["spec"]["template"]["spec"]["containers"][0]["command"] == ["echo", "pong"]
  )'
check_criterion "ping retains two completed successful scheduled runs" history_thinned

print_score
