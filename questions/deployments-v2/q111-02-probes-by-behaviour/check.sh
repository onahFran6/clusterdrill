#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-02-probes-by-behaviour${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Readiness probe is an HTTP GET on path / port 80" \
  bash -c '
    path="$(kubectl get deployment catalog -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].readinessProbe.httpGet.path}" 2>/dev/null)"
    port="$(kubectl get deployment catalog -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].readinessProbe.httpGet.port}" 2>/dev/null)"
    [ "$path" = "/" ] && [ "$port" = "80" ]
  '

check_criterion "Readiness probe starts 5s after container start, checks every 5s" \
  bash -c '
    delay="$(kubectl get deployment catalog -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].readinessProbe.initialDelaySeconds}" 2>/dev/null)"
    period="$(kubectl get deployment catalog -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].readinessProbe.periodSeconds}" 2>/dev/null)"
    [ "$delay" = "5" ] && [ "$period" = "5" ]
  '

check_criterion "Liveness probe is a TCP check on port 80" \
  [ "$(kget deployment catalog '{.spec.template.spec.containers[0].livenessProbe.tcpSocket.port}' -n "$QUESTION_ID")" = "80" ]

check_criterion "Liveness probe restarts after ~30s: periodSeconds=10, failureThreshold=3" \
  bash -c '
    period="$(kubectl get deployment catalog -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].livenessProbe.periodSeconds}" 2>/dev/null)"
    threshold="$(kubectl get deployment catalog -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].livenessProbe.failureThreshold}" 2>/dev/null)"
    [ "$period" = "10" ] && [ "$threshold" = "3" ]
  '

check_criterion "Rollout triggered by the new probes is complete: 3/3 ready" \
  bash -c '
    probe_path="$(kubectl get deployment catalog -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].readinessProbe.httpGet.path}" 2>/dev/null)"
    ready="$(kubectl get deployment catalog -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ -n "$probe_path" ] && [ "$ready" = "3" ]
  '

print_score
