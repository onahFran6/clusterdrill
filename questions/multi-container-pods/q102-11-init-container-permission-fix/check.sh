#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-11-init-container-permission-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

INIT_CMD="$(kget pod secure-app '{.spec.initContainers[?(@.name=="fix-permissions")].command}' -n "$QUESTION_ID")"
check_criterion "init container command references chown/chmod" \
  bash -c "echo '$INIT_CMD' | grep -Eq 'chown|chmod'"

check_criterion "init container command references /data" \
  bash -c "echo '$INIT_CMD' | grep -q /data"

check_criterion "init container mounts data-vol at /data" \
  [ "$(kget pod secure-app '{.spec.initContainers[?(@.name=="fix-permissions")].volumeMounts[?(@.name=="data-vol")].mountPath}' -n "$QUESTION_ID")" = "/data" ]

check_criterion "main container mounts data-vol at /data" \
  [ "$(kget pod secure-app '{.spec.containers[?(@.name=="main")].volumeMounts[?(@.name=="data-vol")].mountPath}' -n "$QUESTION_ID")" = "/data" ]

check_criterion "main container runs as UID 1000" \
  [ "$(kget pod secure-app '{.spec.containers[?(@.name=="main")].securityContext.runAsUser}' -n "$QUESTION_ID")" = "1000" ]

print_score
