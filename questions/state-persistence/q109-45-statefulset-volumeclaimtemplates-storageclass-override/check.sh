#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-45-statefulset-volumeclaimtemplates-storageclass-override${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "StatefulSet 'ledger' exists with 2 replicas and serviceName 'ledger'" \
  bash -c "[ \"\$(kubectl get statefulset ledger -n '$QUESTION_ID' -o jsonpath='{.spec.replicas}')\" = '2' ] && \
    [ \"\$(kubectl get statefulset ledger -n '$QUESTION_ID' -o jsonpath='{.spec.serviceName}')\" = 'ledger' ]"

check_criterion "volumeClaimTemplate 'data' requests 100Mi ReadWriteOnce via storageClassName 'retained-storage'" \
  bash -c "[ \"\$(kubectl get statefulset ledger -n '$QUESTION_ID' -o jsonpath='{.spec.volumeClaimTemplates[0].metadata.name}')\" = 'data' ] && \
    [ \"\$(kubectl get statefulset ledger -n '$QUESTION_ID' -o jsonpath='{.spec.volumeClaimTemplates[0].spec.resources.requests.storage}')\" = '100Mi' ] && \
    [ \"\$(kubectl get statefulset ledger -n '$QUESTION_ID' -o jsonpath='{.spec.volumeClaimTemplates[0].spec.accessModes[0]}')\" = 'ReadWriteOnce' ] && \
    [ \"\$(kubectl get statefulset ledger -n '$QUESTION_ID' -o jsonpath='{.spec.volumeClaimTemplates[0].spec.storageClassName}')\" = 'retained-storage' ]"

check_criterion "Container 'ledger' mounts the volume at /var/lib/ledger" \
  bash -c "
    vol=\$(kubectl get statefulset ledger -n '$QUESTION_ID' -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].name}')
    [ \"\$vol\" = 'data' ] && \
    [ \"\$(kubectl get statefulset ledger -n '$QUESTION_ID' -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}')\" = '/var/lib/ledger' ]
  "

check_criterion "Both per-replica PVCs (data-ledger-0, data-ledger-1) are Bound via retained-storage" \
  bash -c '
    for _ in $(seq 1 15); do
      p0="$(kubectl get pvc data-ledger-0 -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      p1="$(kubectl get pvc data-ledger-1 -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      sc0="$(kubectl get pvc data-ledger-0 -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.storageClassName}" 2>/dev/null)"
      if [ "$p0" = "Bound" ] && [ "$p1" = "Bound" ] && [ "$sc0" = "retained-storage" ]; then exit 0; fi
      sleep 2
    done
    exit 1
  '

check_criterion "Both StatefulSet pods (ledger-0, ledger-1) are Running" \
  bash -c '
    for _ in $(seq 1 15); do
      p0="$(kubectl get pod ledger-0 -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      p1="$(kubectl get pod ledger-1 -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      [ "$p0" = "Running" ] && [ "$p1" = "Running" ] && exit 0
      sleep 2
    done
    exit 1
  '

print_score
