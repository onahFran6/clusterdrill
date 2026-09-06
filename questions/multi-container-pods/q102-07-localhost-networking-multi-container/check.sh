#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-07-localhost-networking-multi-container${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod web-with-healthcheck exists" \
  resource_exists pod web-with-healthcheck -n "$QUESTION_ID"

check_criterion "Pod has exactly 2 containers" \
  [ "$(kget pod web-with-healthcheck '{.spec.containers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "2" ]

check_criterion "'web' container image is nginx:1.27-alpine" \
  [ "$(kget pod web-with-healthcheck '{.spec.containers[?(@.name=="web")].image}' -n "$QUESTION_ID")" = "nginx:1.27-alpine" ]

check_criterion "'web' container exposes containerPort 80" \
  [ "$(kget pod web-with-healthcheck '{.spec.containers[?(@.name=="web")].ports[0].containerPort}' -n "$QUESTION_ID")" = "80" ]

check_criterion "'healthchecker' container image is busybox:1.36" \
  [ "$(kget pod web-with-healthcheck '{.spec.containers[?(@.name=="healthchecker")].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

HEALTHCHECKER_CMD="$(kget pod web-with-healthcheck '{.spec.containers[?(@.name=="healthchecker")].command}' -n "$QUESTION_ID")$(kget pod web-with-healthcheck '{.spec.containers[?(@.name=="healthchecker")].args}' -n "$QUESTION_ID")"
check_criterion "'healthchecker' command targets localhost or 127.0.0.1" \
  bash -c "echo '$HEALTHCHECKER_CMD' | grep -Eq 'localhost|127\.0\.0\.1'"

check_criterion "'healthchecker' command targets port 80" \
  bash -c "echo '$HEALTHCHECKER_CMD' | grep -q ':80'"

print_score
