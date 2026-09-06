#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-02-init-container-wait-for-service${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'app' exists" \
  resource_exists pod app -n "$QUESTION_ID"

INIT_NAME="$(kget pod app '{.spec.initContainers[0].name}' -n "$QUESTION_ID")"
check_criterion "Init container is named 'wait-for-db'" \
  [ "$INIT_NAME" = "wait-for-db" ]

INIT_IMAGE="$(kget pod app '{.spec.initContainers[?(@.name=="wait-for-db")].image}' -n "$QUESTION_ID")"
check_criterion "Init container 'wait-for-db' uses busybox:1.36" \
  [ "$INIT_IMAGE" = "busybox:1.36" ]

INIT_CMD="$(kget pod app '{.spec.initContainers[?(@.name=="wait-for-db")].command}' -n "$QUESTION_ID")"
check_criterion "Init container command references 'user-db'" \
  bash -c "echo '$INIT_CMD' | grep -q user-db"

check_criterion "Init container command checks DNS via nslookup" \
  bash -c "echo '$INIT_CMD' | grep -q nslookup"

MAIN_IMAGE="$(kget pod app '{.spec.containers[?(@.name=="main")].image}' -n "$QUESTION_ID")"
check_criterion "Main container 'main' uses nginx image" \
  bash -c "echo '$MAIN_IMAGE' | grep -q nginx"

print_score
