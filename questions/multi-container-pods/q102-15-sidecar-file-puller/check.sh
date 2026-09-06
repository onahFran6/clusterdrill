#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-15-sidecar-file-puller${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'content-server' has exactly 2 containers" \
  [ "$(kget pod content-server '{.spec.containers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "2" ]

check_criterion "'web' container image is nginx:1.27-alpine" \
  [ "$(kget pod content-server '{.spec.containers[?(@.name=="web")].image}' -n "$QUESTION_ID")" = "nginx:1.27-alpine" ]

check_criterion "'web' mounts web-content at /usr/share/nginx/html" \
  [ "$(kget pod content-server '{.spec.containers[?(@.name=="web")].volumeMounts[?(@.name=="web-content")].mountPath}' -n "$QUESTION_ID")" = "/usr/share/nginx/html" ]

CONTENT_PULLER_VOL="$(kget pod content-server '{.spec.containers[?(@.name=="content-puller")].volumeMounts[?(@.name=="web-content")].name}' -n "$QUESTION_ID")"
check_criterion "'content-puller' mounts web-content (any path)" \
  [ -n "$CONTENT_PULLER_VOL" ]

CONTENT_PULLER_CMD="$(kget pod content-server '{.spec.containers[?(@.name=="content-puller")].command}' -n "$QUESTION_ID")"
check_criterion "'content-puller' command references index.html" \
  bash -c "echo '$CONTENT_PULLER_CMD' | grep -q index.html"

print_score
