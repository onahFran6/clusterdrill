#!/usr/bin/env bash
# Failed criteria must not abort the checklist.
set -uo pipefail

QUESTION_ID="q118-20-cronjob-behind-deny-all${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
    # Rule ordering does not change NetworkPolicy permissions.
    def normalized(value):
        if isinstance(value, dict):
            return tuple(sorted((key, normalized(item)) for key, item in value.items()))
        if isinstance(value, list):
            return tuple(sorted((normalized(item) for item in value), key=repr))
        return value
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

check_criterion 'reporter preserves its workload and labels every run consistently' \
  json_check cronjob reporter '(
    d["spec"]["jobTemplate"]["spec"]["template"]["spec"]["containers"][0]["image"] == "busybox:1.36"
    and d["spec"]["schedule"] == "*/15 * * * *"
    and d["spec"]["jobTemplate"]["spec"]["template"]["metadata"]["labels"]["app"] == "reporter"
    and d["spec"]["jobTemplate"]["spec"]["template"]["spec"]["containers"][0]["command"] == ["wget", "-qO-", "-T", "5", "report-svc:8080"]
  )'
check_criterion 'reporter egress permits only backend TCP 8080 and CoreDNS UDP/TCP 53' \
  json_check networkpolicy reporter-egress 'normalized(d["spec"]) == normalized({"podSelector": {"matchLabels": {"app": "reporter"}}, "policyTypes": ["Egress"], "egress": [{"to": [{"podSelector": {"matchLabels": {"app": "report"}}}], "ports": [{"protocol": "TCP", "port": 8080}]}, {"to": [{"namespaceSelector": {"matchLabels": {"kubernetes.io/metadata.name": "kube-system"}}, "podSelector": {"matchLabels": {"k8s-app": "kube-dns"}}}], "ports": [{"protocol": "UDP", "port": 53}, {"protocol": "TCP", "port": 53}]}]})'
check_criterion 'report ingress permits only reporter TCP 8080' \
  json_check networkpolicy report-from-reporter 'normalized(d["spec"]) == normalized({"podSelector": {"matchLabels": {"app": "report"}}, "policyTypes": ["Ingress"], "ingress": [{"from": [{"podSelector": {"matchLabels": {"app": "reporter"}}}], "ports": [{"protocol": "TCP", "port": 8080}]}]})'
check_criterion 'reporter-now completed' \
  json_check job reporter-now 'd.get("status", {}).get("succeeded", 0) == 1'
check_criterion 'Manual reporter logs the backend response' log_check job/reporter-now '^report ok\s*$' ''

deny_preserved() {
  json_check job reporter-now 'd.get("status", {}).get("succeeded") == 1' &&
    json_check networkpolicies --all '{p["metadata"]["name"] for p in d["items"]} == {"deny-all", "reporter-egress", "report-from-reporter"}' &&
    json_check networkpolicy deny-all 'd["spec"].get("podSelector") == {} and set(d["spec"]["policyTypes"]) == {"Ingress", "Egress"} and not d["spec"].get("ingress") and not d["spec"].get("egress")'
}
check_criterion "Only the two requested allowances supplement the intact deny-all policy" deny_preserved

print_score
