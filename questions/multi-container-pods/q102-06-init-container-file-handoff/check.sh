#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-06-init-container-file-handoff${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod configured-app exists" \
  resource_exists pod configured-app -n "$QUESTION_ID"

check_criterion "Pod has exactly 1 init container named generate-config" \
  [ "$(kget pod configured-app '{.spec.initContainers[*].name}' -n "$QUESTION_ID")" = "generate-config" ]

INIT_IMAGE="$(kget pod configured-app '{.spec.initContainers[?(@.name=="generate-config")].image}' -n "$QUESTION_ID")"
check_criterion "init container image is busybox:1.36" \
  [ "$INIT_IMAGE" = "busybox:1.36" ]

INIT_CMD="$(kget pod configured-app '{.spec.initContainers[?(@.name=="generate-config")].command}' -n "$QUESTION_ID")$(kget pod configured-app '{.spec.initContainers[?(@.name=="generate-config")].args}' -n "$QUESTION_ID")"
check_criterion "init container command references app.conf" \
  bash -c "echo '$INIT_CMD' | grep -q app.conf"

check_criterion "init container command references mode=production" \
  bash -c "echo '$INIT_CMD' | grep -q mode=production"

check_criterion "init container mounts config-vol" \
  [ "$(kget pod configured-app '{.spec.initContainers[?(@.name=="generate-config")].volumeMounts[?(@.name=="config-vol")].name}' -n "$QUESTION_ID")" = "config-vol" ]

check_criterion "main container 'main' present with busybox image" \
  [ "$(kget pod configured-app '{.spec.containers[?(@.name=="main")].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "main container mounts config-vol at /config" \
  [ "$(kget pod configured-app '{.spec.containers[?(@.name=="main")].volumeMounts[?(@.name=="config-vol")].mountPath}' -n "$QUESTION_ID")" = "/config" ]

check_criterion "pod defines a config-vol emptyDir volume" \
  [ "$(kget pod configured-app '{.spec.volumes[?(@.name=="config-vol")].name}' -n "$QUESTION_ID")" = "config-vol" ]

print_score
