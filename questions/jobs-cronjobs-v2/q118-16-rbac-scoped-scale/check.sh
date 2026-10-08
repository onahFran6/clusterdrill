#!/usr/bin/env bash
# Failed criteria must not abort the checklist.
set -uo pipefail

QUESTION_ID="q118-16-rbac-scoped-scale${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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

scale_permissions() {
  local identity="system:serviceaccount:$QUESTION_ID:night-scaler"
  [[ "$(kubectl auth can-i get deployments --subresource=scale -n "$QUESTION_ID" --as="$identity")" == yes ]] || return 1
  [[ "$(kubectl auth can-i patch deployments --subresource=scale -n "$QUESTION_ID" --as="$identity")" == yes ]] || return 1
  [[ "$(kubectl auth can-i delete deployments -n "$QUESTION_ID" --as="$identity")" == no ]] || return 1
  [[ "$(kubectl auth can-i patch deployments -n "$QUESTION_ID" --as="$identity")" == no ]]
}

check_criterion 'night-scaler Role grants exactly get and patch on deployments/scale' \
  json_check role night-scaler '(
    len(d["rules"]) == 1
    and set(d["rules"][0]["apiGroups"]) == {"apps"}
    and set(d["rules"][0]["resources"]) == {"deployments/scale"}
    and set(d["rules"][0]["verbs"]) == {"get", "patch"}
    and not d["rules"][0].get("resourceNames")
  )'
check_criterion "ServiceAccount can read and patch scale but cannot patch or delete Deployments" scale_permissions
check_criterion 'night-scale uses its own account and the 22:00 Lagos schedule' \
  json_check cronjob night-scale '(
    d["spec"]["schedule"] == "0 22 * * *"
    and d["spec"]["timeZone"] == "Africa/Lagos"
    and d["spec"]["jobTemplate"]["spec"]["template"]["spec"]["serviceAccountName"] == "night-scaler"
    and d["spec"]["jobTemplate"]["spec"]["template"]["spec"]["containers"][0]["image"] == "curlimages/curl:8.10.1"
  )'
check_criterion 'web was scaled to one replica' \
  json_check deployment web 'd["spec"]["replicas"] == 1'
check_criterion 'night-scale-now completed' \
  json_check job night-scale-now 'd.get("status", {}).get("succeeded", 0) == 1'
check_criterion 'Manual scale call returned HTTP 200' log_check job/night-scale-now '^scale patch: 200\s*$' ''

print_score
