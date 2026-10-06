#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-10-slow-starter-probes${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Startup probe: exec cat /tmp/started, period 2s, failureThreshold 30" \
  bash -c '
    cmd="$(kubectl get pod slowboot -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].startupProbe.exec.command}" 2>/dev/null)"
    period="$(kubectl get pod slowboot -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].startupProbe.periodSeconds}" 2>/dev/null)"
    threshold="$(kubectl get pod slowboot -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].startupProbe.failureThreshold}" 2>/dev/null)"
    echo "$cmd" | grep -q "/tmp/started" && [ "$period" = "2" ] && [ "$threshold" -ge 30 ]
  '

check_criterion "Liveness probe: exec cat /tmp/healthy, period 5s" \
  bash -c '
    cmd="$(kubectl get pod slowboot -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].livenessProbe.exec.command}" 2>/dev/null)"
    period="$(kubectl get pod slowboot -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].livenessProbe.periodSeconds}" 2>/dev/null)"
    echo "$cmd" | grep -q "/tmp/healthy" && [ "$period" = "5" ]
  '

check_criterion "Readiness probe: exec cat /tmp/ready, period 3s" \
  bash -c '
    cmd="$(kubectl get pod slowboot -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].readinessProbe.exec.command}" 2>/dev/null)"
    period="$(kubectl get pod slowboot -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].readinessProbe.periodSeconds}" 2>/dev/null)"
    echo "$cmd" | grep -q "/tmp/ready" && [ "$period" = "3" ]
  '

check_criterion "Container booted successfully (started=true, never restarted)" \
  bash -c '
    started="$(kubectl get pod slowboot -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].started}" 2>/dev/null)"
    restarts="$(kubectl get pod slowboot -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].restartCount}" 2>/dev/null)"
    [ "$started" = "true" ] && [ "$restarts" = "0" ]
  '

check_criterion "After /tmp/ready is removed, Pod shows 0/1 Ready without ever restarting" \
  bash -c '
    for i in $(seq 1 10); do
      ready="$(kubectl get pod slowboot -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].ready}" 2>/dev/null)"
      restarts="$(kubectl get pod slowboot -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].restartCount}" 2>/dev/null)"
      [ "$ready" = "false" ] && [ "$restarts" = "0" ] && exit 0
      sleep 2
    done
    exit 1
  '

print_score
