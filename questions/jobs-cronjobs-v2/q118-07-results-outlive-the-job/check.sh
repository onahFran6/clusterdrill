#!/usr/bin/env bash
# Failed criteria must not abort the checklist.
set -uo pipefail

QUESTION_ID="q118-07-results-outlive-the-job${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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

results_survive() {
  json_check pvc results 'd["spec"]["resources"]["requests"]["storage"] == "100Mi" and d.get("status", {}).get("phase") == "Bound"' || return 1
  json_check pod dashboard 'd.get("status", {}).get("phase") == "Succeeded" and any(v.get("persistentVolumeClaim", {}).get("claimName") == "results" and any(m.get("name") == v["name"] and m.get("mountPath") == "/results" for m in d["spec"]["containers"][0].get("volumeMounts", [])) for v in d["spec"].get("volumes", [])) and d["spec"]["containers"][0]["command"] == ["cat", "/results/latest.txt"]' || return 1
  # Require a successful API query before asserting absence.
  local remaining
  remaining="$(kubectl get job calc -n "$QUESTION_ID" --ignore-not-found -o name)" || return 1
  [[ -z "$remaining" ]] || return 1
  kubectl get namespace "$QUESTION_ID" >/dev/null 2>&1 || return 1
  log_check dashboard '^total=42\s*$'
}

check_criterion "The bound 100Mi claim and dashboard retain total=42 after calc is gone" results_survive

print_score
