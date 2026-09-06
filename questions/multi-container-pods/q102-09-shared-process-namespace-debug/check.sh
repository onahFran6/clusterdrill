#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-09-shared-process-namespace-debug${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod debuggable-app exists" \
  resource_exists pod debuggable-app -n "$QUESTION_ID"

check_criterion "spec.shareProcessNamespace is true" \
  [ "$(kget pod debuggable-app '{.spec.shareProcessNamespace}' -n "$QUESTION_ID")" = "true" ]

check_criterion "Pod has exactly 2 containers" \
  [ "$(kget pod debuggable-app '{.spec.containers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "2" ]

check_criterion "'main' container image is nginx:1.27-alpine" \
  [ "$(kget pod debuggable-app '{.spec.containers[?(@.name=="main")].image}' -n "$QUESTION_ID")" = "nginx:1.27-alpine" ]

check_criterion "'debugger' container image is busybox:1.36" \
  [ "$(kget pod debuggable-app '{.spec.containers[?(@.name=="debugger")].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

print_score
