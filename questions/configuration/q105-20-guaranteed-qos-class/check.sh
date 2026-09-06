#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-20-guaranteed-qos-class${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

_cpu_request="$(kget pod critical-job '{.spec.containers[0].resources.requests.cpu}' -n "$QUESTION_ID")"
_cpu_limit="$(kget pod critical-job '{.spec.containers[0].resources.limits.cpu}' -n "$QUESTION_ID")"
_mem_request="$(kget pod critical-job '{.spec.containers[0].resources.requests.memory}' -n "$QUESTION_ID")"
_mem_limit="$(kget pod critical-job '{.spec.containers[0].resources.limits.memory}' -n "$QUESTION_ID")"

check_criterion "CPU request equals CPU limit (300m)" \
  bash -c "[ '$_cpu_request' = '300m' ] && [ '$_cpu_limit' = '300m' ]"

check_criterion "Memory request equals memory limit (256Mi)" \
  bash -c "[ '$_mem_request' = '256Mi' ] && [ '$_mem_limit' = '256Mi' ]"

check_criterion "Pod 'critical-job' has QoS class Guaranteed" \
  [ "$(kget pod critical-job '{.status.qosClass}' -n "$QUESTION_ID")" = "Guaranteed" ]

print_score
