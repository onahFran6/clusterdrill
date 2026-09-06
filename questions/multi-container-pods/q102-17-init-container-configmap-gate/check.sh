#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-17-init-container-configmap-gate${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'app-config' exists" \
  resource_exists configmap app-config -n "$QUESTION_ID"

check_criterion "ConfigMap 'app-config' has APP_MODE=production" \
  [ "$(kget configmap app-config '{.data.APP_MODE}' -n "$QUESTION_ID")" = "production" ]

check_criterion "Pod 'configmap-gated-app' has at least 1 init container" \
  [ -n "$(kget pod configmap-gated-app '{.spec.initContainers[0].name}' -n "$QUESTION_ID")" ]

check_criterion "Main container 'main' exists with busybox image" \
  [ "$(kget pod configmap-gated-app '{.spec.containers[?(@.name=="main")].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "'main' container envFrom references configMapRef app-config" \
  [ "$(kget pod configmap-gated-app '{.spec.containers[?(@.name=="main")].envFrom[0].configMapRef.name}' -n "$QUESTION_ID")" = "app-config" ]

print_score
