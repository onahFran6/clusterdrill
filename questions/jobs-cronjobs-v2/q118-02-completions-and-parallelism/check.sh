#!/usr/bin/env bash
# Failed criteria must not abort the checklist.
set -uo pipefail

QUESTION_ID="q118-02-completions-and-parallelism${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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

# Literal container command; do not expand $(hostname) on the grading host.
# shellcheck disable=SC2016
check_criterion 'render keeps the requested workload and runs six successes with parallelism two' \
  json_check job render '(
    d["spec"]["template"]["spec"]["containers"][0]["image"] == "busybox:1.36"
    and d["spec"]["completions"] == 6
    and d["spec"]["parallelism"] == 2
    and d["spec"]["template"]["spec"]["containers"][0]["command"] == ["sh", "-c", "echo rendering on $(hostname); sleep 5"]
  )'
check_criterion 'render created exactly six successful Pods' \
  json_check pods '-l job-name=render' '(
    len(d["items"]) == 6
    and all(p.get("status", {}).get("phase") == "Succeeded" for p in d["items"])
  )'

print_score
