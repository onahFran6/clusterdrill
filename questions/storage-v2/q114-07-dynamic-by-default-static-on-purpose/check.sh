#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-07-dynamic-by-default-static-on-purpose${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC dyn's live storageClassName equals the cluster's actual default class" \
  bash -c '
    default_sc="$(kubectl get sc -o jsonpath="{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class==\"true\")]}{.metadata.name}{end}")"
    [ -n "$default_sc" ] || exit 1
    sc="$(kubectl get pvc dyn -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.storageClassName}" 2>/dev/null)"
    [ "$sc" = "$default_sc" ]
  '

check_criterion "PVC stat has storageClassName=\"\" and is Bound to q114-07-static-pv" \
  bash -c '
    sc="$(kubectl get pvc stat -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.storageClassName}" 2>/dev/null)"
    phase="$(kubectl get pvc stat -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    vol="$(kubectl get pvc stat -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumeName}" 2>/dev/null)"
    [ "$sc" = "" ] && [ "$phase" = "Bound" ] && [ "$vol" = "q114-07-static-pv" ]
  '

check_criterion "Pod seine-app mounts both dyn and stat" \
  bash -c '
    dyn_name="$(kubectl get pod seine-app -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[?(@.persistentVolumeClaim.claimName==\"dyn\")].name}" 2>/dev/null)"
    stat_name="$(kubectl get pod seine-app -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[?(@.persistentVolumeClaim.claimName==\"stat\")].name}" 2>/dev/null)"
    [ -n "$dyn_name" ] && [ -n "$stat_name" ]
  '

check_criterion "Pod seine-app is Running" \
  bash -c '[ "$(kubectl get pod seine-app -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)" = "Running" ]'

print_score
