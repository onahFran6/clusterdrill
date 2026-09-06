#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-10-native-sidecar-restart-always${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod has exactly 1 initContainers entry" \
  [ "$(kget pod native-sidecar-app '{.spec.initContainers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "1" ]

check_criterion "initContainer is named sidecar-log-agent" \
  [ "$(kget pod native-sidecar-app '{.spec.initContainers[0].name}' -n "$QUESTION_ID")" = "sidecar-log-agent" ]

check_criterion "initContainer image is busybox:1.36" \
  [ "$(kget pod native-sidecar-app '{.spec.initContainers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "initContainer restartPolicy is exactly Always" \
  [ "$(kget pod native-sidecar-app '{.spec.initContainers[0].restartPolicy}' -n "$QUESTION_ID")" = "Always" ]

check_criterion "main container image is nginx" \
  [ "$(kget pod native-sidecar-app '{.spec.containers[?(@.name=="main")].image}' -n "$QUESTION_ID")" = "nginx:1.27-alpine" ]

print_score
