#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-08-configmap-volume-mount-whole${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'report-service' mounts a volume backed by ConfigMap app-config" \
  bash -c "kubectl get pod report-service -n '$QUESTION_ID' -o json 2>/dev/null | grep -q '\"app-config\"'"

check_criterion "That volume is mounted at /etc/app-config" \
  [ "$(kget pod report-service '{.spec.containers[0].volumeMounts[0].mountPath}' -n "$QUESTION_ID")" = "/etc/app-config" ]

check_criterion "app.properties file is present in the container" \
  bash -c "kubectl exec -n '$QUESTION_ID' report-service -- cat /etc/app-config/app.properties 2>/dev/null | grep -q 'retries=3'"

check_criterion "logging.properties file is present in the container" \
  bash -c "kubectl exec -n '$QUESTION_ID' report-service -- cat /etc/app-config/logging.properties 2>/dev/null | grep -q 'level=INFO'"

print_score
