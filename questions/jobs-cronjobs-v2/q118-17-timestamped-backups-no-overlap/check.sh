#!/usr/bin/env bash
# Failed criteria must not abort the checklist.
set -uo pipefail

QUESTION_ID="q118-17-timestamped-backups-no-overlap${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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

backup_folders() {
  resource_exists pvc backups -n "$QUESTION_ID" || return 1
  json_check job backup-1 'd.get("status", {}).get("succeeded") == 1' || return 1
  json_check job backup-2 'd.get("status", {}).get("succeeded") == 1' || return 1
  local NS="$QUESTION_ID" output status
  local probe_name="clusterdrill-inspect-${RANDOM}"
  kubectl apply -n "$NS" -f - <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: $probe_name
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  restartPolicy: Never
  volumes:
  - name: backups
    persistentVolumeClaim:
      claimName: backups
      readOnly: true
  containers:
  - name: inspect
    image: busybox:1.36
    command:
    - sh
    - -c
    - for d in /backups/*; do [ -d "\$d" ] && [ -s "\$d/notes.log" ] || exit 1; basename "\$d"; done
    volumeMounts:
    - name: backups
      mountPath: /backups
      readOnly: true
YAML
  kubectl wait -n "$NS" --for=jsonpath='{.status.phase}'=Succeeded "pod/$probe_name" --timeout=35s >/dev/null
  status=$?
  output="$(kubectl logs "$probe_name" -n "$NS" 2>/dev/null)"
  kubectl delete pod "$probe_name" -n "$NS" --ignore-not-found --wait=false >/dev/null
  [[ "$status" == 0 ]] || return 1
  printf '%s\n' "$output" | python3 -c 'import re, sys; lines=sys.stdin.read().splitlines(); sys.exit(0 if len(lines)==2 and len(set(lines))==2 and all(re.fullmatch(r"[0-9]{8}-[0-9]{6}", s) for s in lines) else 1)'
}

check_criterion 'backup retains its six-hour workload, prevents overlap, and uses read-only data' \
  json_check cronjob backup '(
    d["spec"]["jobTemplate"]["spec"]["template"]["spec"]["containers"][0]["image"] == "busybox:1.36"
    and d["spec"]["schedule"] == "0 */6 * * *"
    and d["spec"]["concurrencyPolicy"] == "Forbid"
    and any(v.get("persistentVolumeClaim", {}).get("claimName") == "data" and v["persistentVolumeClaim"].get("readOnly") is True for v in d["spec"]["jobTemplate"]["spec"]["template"]["spec"]["volumes"])
    and any(m.get("mountPath") == "/data" and m.get("readOnly") is True for m in d["spec"]["jobTemplate"]["spec"]["template"]["spec"]["containers"][0]["volumeMounts"])
  )'
check_criterion 'backups is a bound 200Mi claim' \
  json_check pvc backups '(
    d["spec"]["resources"]["requests"]["storage"] == "200Mi"
    and d.get("status", {}).get("phase") == "Bound"
  )'
check_criterion "Two timestamped backup folders each contain nonempty notes.log" backup_folders

print_score
