#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-38-downward-api-podinfo-env${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'info-reporter' exists and is Running" \
  bash -c '
    phase="$(kubectl get pod info-reporter -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Running" ]
  '

check_criterion "env MY_POD_NAME is sourced via fieldRef metadata.name" \
  [ "$(kget pod info-reporter '{.spec.containers[0].env[?(@.name=="MY_POD_NAME")].valueFrom.fieldRef.fieldPath}' -n "$QUESTION_ID")" = "metadata.name" ]

check_criterion "env MY_POD_NAMESPACE is sourced via fieldRef metadata.namespace" \
  [ "$(kget pod info-reporter '{.spec.containers[0].env[?(@.name=="MY_POD_NAMESPACE")].valueFrom.fieldRef.fieldPath}' -n "$QUESTION_ID")" = "metadata.namespace" ]

check_criterion "env MY_POD_IP is sourced via fieldRef status.podIP" \
  [ "$(kget pod info-reporter '{.spec.containers[0].env[?(@.name=="MY_POD_IP")].valueFrom.fieldRef.fieldPath}' -n "$QUESTION_ID")" = "status.podIP" ]

check_criterion "Container actually sees MY_POD_NAME=info-reporter and MY_POD_NAMESPACE=$QUESTION_ID" \
  bash -c '
    name="$(kubectl exec -n "'"$QUESTION_ID"'" info-reporter -- sh -c "echo \$MY_POD_NAME" 2>/dev/null)"
    [ "$name" = "info-reporter" ] || exit 1
    ns="$(kubectl exec -n "'"$QUESTION_ID"'" info-reporter -- sh -c "echo \$MY_POD_NAMESPACE" 2>/dev/null)"
    [ "$ns" = "'"$QUESTION_ID"'" ]
  '

print_score
