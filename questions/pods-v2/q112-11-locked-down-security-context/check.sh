#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-11-locked-down-security-context${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod-level securityContext: runAsUser=1000, runAsGroup=3000, fsGroup=2000" \
  bash -c '
    uid="$(kubectl get pod locked -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.securityContext.runAsUser}" 2>/dev/null)"
    gid="$(kubectl get pod locked -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.securityContext.runAsGroup}" 2>/dev/null)"
    fsgroup="$(kubectl get pod locked -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.securityContext.fsGroup}" 2>/dev/null)"
    [ "$uid" = "1000" ] && [ "$gid" = "3000" ] && [ "$fsgroup" = "2000" ]
  '

check_criterion "readOnlyRootFilesystem/allowPrivilegeEscalation/capabilities live on the container only, not the Pod" \
  bash -c '
    ro="$(kubectl get pod locked -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].securityContext.readOnlyRootFilesystem}" 2>/dev/null)"
    pe="$(kubectl get pod locked -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].securityContext.allowPrivilegeEscalation}" 2>/dev/null)"
    drop="$(kubectl get pod locked -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].securityContext.capabilities.drop[0]}" 2>/dev/null)"
    ro_pod="$(kubectl get pod locked -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.securityContext.readOnlyRootFilesystem}" 2>/dev/null)"
    pe_pod="$(kubectl get pod locked -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.securityContext.allowPrivilegeEscalation}" 2>/dev/null)"
    [ "$ro" = "true" ] && [ "$pe" = "false" ] && [ "$drop" = "ALL" ] && [ -z "$ro_pod" ] && [ -z "$pe_pod" ]
  '

check_criterion "Volume 'data' is an emptyDir mounted at /data" \
  bash -c '
    kind="$(kubectl get pod locked -n "'"$QUESTION_ID"'" -o json 2>/dev/null | jq -e ".spec.volumes[] | select(.name==\"data\") | has(\"emptyDir\")" >/dev/null 2>&1 && echo yes)"
    mountpath="$(kubectl get pod locked -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].volumeMounts[0].mountPath}" 2>/dev/null)"
    [ "$kind" = "yes" ] && [ "$mountpath" = "/data" ]
  '

check_criterion "Pod is Running" \
  bash -c '[ "$(kubectl get pod locked -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)" = "Running" ]'

check_criterion "id shows uid=1000 gid=3000, and the root filesystem is actually read-only" \
  bash -c '
    idout="$(kubectl exec locked -n "'"$QUESTION_ID"'" -- id 2>/dev/null)"
    echo "$idout" | grep -q "uid=1000" && echo "$idout" | grep -q "gid=3000" \
      && ! kubectl exec locked -n "'"$QUESTION_ID"'" -- touch /root-test >/dev/null 2>&1
  '

check_criterion "A new file in /data is owned uid=1000, group=2000 (fsGroup)" \
  bash -c '
    out="$(kubectl exec locked -n "'"$QUESTION_ID"'" -- sh -c "touch /data/f; ls -ln /data/f" 2>/dev/null)"
    echo "$out" | awk "{print \$3, \$4}" | grep -q "^1000 2000$"
  '

print_score
