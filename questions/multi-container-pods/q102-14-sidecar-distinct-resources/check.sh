#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-14-sidecar-distinct-resources${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "main image is nginx:1.27-alpine" \
  [ "$(kget pod resource-aware-app '{.spec.containers[?(@.name=="main")].image}' -n "$QUESTION_ID")" = "nginx:1.27-alpine" ]

check_criterion "main requests.cpu is 100m" \
  [ "$(kget pod resource-aware-app '{.spec.containers[?(@.name=="main")].resources.requests.cpu}' -n "$QUESTION_ID")" = "100m" ]

check_criterion "main requests.memory is 64Mi" \
  [ "$(kget pod resource-aware-app '{.spec.containers[?(@.name=="main")].resources.requests.memory}' -n "$QUESTION_ID")" = "64Mi" ]

check_criterion "main limits.cpu is 250m" \
  [ "$(kget pod resource-aware-app '{.spec.containers[?(@.name=="main")].resources.limits.cpu}' -n "$QUESTION_ID")" = "250m" ]

check_criterion "main limits.memory is 128Mi" \
  [ "$(kget pod resource-aware-app '{.spec.containers[?(@.name=="main")].resources.limits.memory}' -n "$QUESTION_ID")" = "128Mi" ]

check_criterion "metrics-sidecar image is busybox:1.36" \
  [ "$(kget pod resource-aware-app '{.spec.containers[?(@.name=="metrics-sidecar")].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "metrics-sidecar requests.cpu is 50m" \
  [ "$(kget pod resource-aware-app '{.spec.containers[?(@.name=="metrics-sidecar")].resources.requests.cpu}' -n "$QUESTION_ID")" = "50m" ]

check_criterion "metrics-sidecar requests.memory is 32Mi" \
  [ "$(kget pod resource-aware-app '{.spec.containers[?(@.name=="metrics-sidecar")].resources.requests.memory}' -n "$QUESTION_ID")" = "32Mi" ]

check_criterion "metrics-sidecar limits.cpu is 100m" \
  [ "$(kget pod resource-aware-app '{.spec.containers[?(@.name=="metrics-sidecar")].resources.limits.cpu}' -n "$QUESTION_ID")" = "100m" ]

check_criterion "metrics-sidecar limits.memory is 64Mi" \
  [ "$(kget pod resource-aware-app '{.spec.containers[?(@.name=="metrics-sidecar")].resources.limits.memory}' -n "$QUESTION_ID")" = "64Mi" ]

print_score
