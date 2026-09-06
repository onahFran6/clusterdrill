#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-46-fix-stuck-rollout-bad-readiness-probe${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

deployment_ready_three() {
  local i image name replicas path port
  for ((i = 0; i < 30; i++)); do
    image="$(kget deployment web-front '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")"
    name="$(kget deployment web-front '{.spec.template.spec.containers[0].name}' -n "$QUESTION_ID")"
    replicas="$(kget deployment web-front '{.spec.replicas}' -n "$QUESTION_ID")"
    path="$(kget deployment web-front '{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' -n "$QUESTION_ID")"
    port="$(kget deployment web-front '{.spec.template.spec.containers[0].readinessProbe.httpGet.port}' -n "$QUESTION_ID")"
    if [ "$(kget deployment web-front '{.status.readyReplicas}' -n "$QUESTION_ID")" = "3" ] \
      && [ "$image" = "nginx:1.25-alpine" ] \
      && [ "$name" = "web-front" ] \
      && [ "$replicas" = "3" ] \
      && [ "$path" = "/" ] \
      && [ "$port" = "80" ]; then
      return 0
    fi
    sleep 3
  done
  return 1
}
check_criterion "Deployment 'web-front' keeps its workload settings, fixes readinessProbe path to '/', and reaches readyReplicas=3" \
  deployment_ready_three

print_score
