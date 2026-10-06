#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-15-the-reporter-never-starts${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC reports requests 100Mi on the cluster's actual default StorageClass" \
  bash -c '
    default_sc="$(kubectl get sc -o jsonpath="{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class==\"true\")]}{.metadata.name}{end}")"
    [ -n "$default_sc" ] || exit 1
    req="$(kubectl get pvc reports -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.resources.requests.storage}" 2>/dev/null)"
    sc="$(kubectl get pvc reports -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.storageClassName}" 2>/dev/null)"
    [ "$req" = "100Mi" ] && [ "$sc" = "$default_sc" ]
  '

check_criterion "Deployment reporter's volume references claim name 'reports' (typo fixed)" \
  bash -c '[ "$(kubectl get deployment reporter -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}" 2>/dev/null)" = "reports" ]'

check_criterion "Deployment reporter is 1/1 Running" \
  bash -c '
    for i in $(seq 1 10); do
      ready="$(kubectl get deployment reporter -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
      [ "$ready" = "1" ] && exit 0
      sleep 3
    done
    exit 1
  '

print_score
