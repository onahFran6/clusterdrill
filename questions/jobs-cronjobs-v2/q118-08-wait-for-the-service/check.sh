#!/usr/bin/env bash
# Failed criteria must not abort the checklist.
set -uo pipefail

QUESTION_ID="q118-08-wait-for-the-service${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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

check_criterion 'seed uses wait-db to resolve this namespace database before seeding' \
  json_check job seed '(
    d["spec"]["template"]["spec"]["containers"][0]["image"] == "busybox:1.36"
    and d["spec"]["template"]["spec"]["containers"][0]["command"] == ["echo", "seeding db"]
    and any(c["name"] == "wait-db" and c["image"] == "busybox:1.36" and f"nslookup db.{sys.argv[2]}.svc.cluster.local" in " ".join(c.get("command", [])) for c in d["spec"]["template"]["spec"].get("initContainers", []))
  )'
check_criterion 'db exposes TCP 5432 as a ClusterIP Service' \
  json_check service db '(
    d["spec"]["type"] == "ClusterIP"
    and any(p["port"] == 5432 and p["targetPort"] == 5432 and p["protocol"] == "TCP" for p in d["spec"]["ports"])
  )'
check_criterion 'seed completed once' \
  json_check job seed 'd.get("status", {}).get("succeeded", 0) == 1'
check_criterion 'seed logs its successful database seeding' log_check job/seed '^seeding db\s*$' seed

print_score
