#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-08-init-container-wait-for-dns${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Init container 'wait-db' (busybox:1.36) loops on the Service name" \
  bash -c '
    name="$(kubectl get pod api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.initContainers[0].name}" 2>/dev/null)"
    image="$(kubectl get pod api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.initContainers[0].image}" 2>/dev/null)"
    cmd="$(kubectl get pod api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.initContainers[0]}" 2>/dev/null)"
    [ "$name" = "wait-db" ] && [ "$image" = "busybox:1.36" ] && echo "$cmd" | grep -q "db"
  '

check_criterion "Service 'db' is a ClusterIP TCP service on port 5432" \
  bash -c '
    type="$(kubectl get svc db -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.type}" 2>/dev/null)"
    port="$(kubectl get svc db -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.ports[0].port}" 2>/dev/null)"
    proto="$(kubectl get svc db -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.ports[0].protocol}" 2>/dev/null)"
    [ "$type" = "ClusterIP" ] && [ "$port" = "5432" ] && [ "$proto" = "TCP" ]
  '

check_criterion "Pod 'api' is Running with both containers ready" \
  bash -c '
    for i in $(seq 1 15); do
      phase="$(kubectl get pod api -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      ready="$(kubectl get pod api -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].ready}" 2>/dev/null)"
      [ "$phase" = "Running" ] && [ "$ready" = "true" ] && exit 0
      sleep 2
    done
    exit 1
  '

check_criterion "wait-db's own logs confirm it found the Service" \
  bash -c 'kubectl logs api -c wait-db -n "'"$QUESTION_ID"'" 2>/dev/null | tail -1 | grep -q found'

print_score
