#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-20-expose-pod-and-debug-ephemeral-container${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'api-svc' is ClusterIP, port 80, targets the container port by name" \
  bash -c '
    type="$(kubectl get svc api-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.type}" 2>/dev/null)"
    port="$(kubectl get svc api-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.ports[0].port}" 2>/dev/null)"
    targetport="$(kubectl get svc api-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.ports[0].targetPort}" 2>/dev/null)"
    [ "$type" = "ClusterIP" ] && [ "$port" = "80" ] && [ "$targetport" = "http" ]
  '

check_criterion "Requesting api-svc from inside the cluster succeeds" \
  bash -c '
    for i in $(seq 1 6); do
      code="$(kubectl run q112-20-probe --rm -i --restart=Never --image=curlimages/curl:8.10.1 -n "'"$QUESTION_ID"'" \
        --command -- sh -c "curl -s -o /dev/null -w \"%{http_code}\" --max-time 5 http://api-svc" 2>/dev/null)"
      # kubectl run --rm appends a "pod ... deleted" status line onto the
      # same stdout stream right after curl'"'"'s 3-digit code, so only the
      # leading 3 characters are the actual HTTP status.
      [ "${code:0:3}" = "200" ] && exit 0
      sleep 3
    done
    exit 1
  '

check_criterion "Ephemeral container 'dbg' (busybox:1.36) targets 'web'" \
  bash -c '
    name="$(kubectl get pod api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.ephemeralContainers[0].name}" 2>/dev/null)"
    image="$(kubectl get pod api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.ephemeralContainers[0].image}" 2>/dev/null)"
    target="$(kubectl get pod api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.ephemeralContainers[0].targetContainerName}" 2>/dev/null)"
    [ "$name" = "dbg" ] && [ "$image" = "busybox:1.36" ] && [ "$target" = "web" ]
  '

check_criterion "dbg's logs show it saw nginx's own processes (shared process namespace)" \
  bash -c 'kubectl logs api -c dbg -n "'"$QUESTION_ID"'" 2>/dev/null | grep -q nginx'

print_score
