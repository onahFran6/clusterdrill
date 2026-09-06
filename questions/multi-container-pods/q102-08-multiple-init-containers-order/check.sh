#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-08-multiple-init-containers-order${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod ordered-init-app exists" \
  resource_exists pod ordered-init-app -n "$QUESTION_ID"

check_criterion "Pod has exactly 2 init containers" \
  [ "$(kget pod ordered-init-app '{.spec.initContainers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "2" ]

check_criterion "initContainers[0] is named init-first" \
  [ "$(kget pod ordered-init-app '{.spec.initContainers[0].name}' -n "$QUESTION_ID")" = "init-first" ]

check_criterion "initContainers[1] is named init-second" \
  [ "$(kget pod ordered-init-app '{.spec.initContainers[1].name}' -n "$QUESTION_ID")" = "init-second" ]

check_criterion "init-first mounts work-vol" \
  [ "$(kget pod ordered-init-app '{.spec.initContainers[?(@.name=="init-first")].volumeMounts[?(@.name=="work-vol")].name}' -n "$QUESTION_ID")" = "work-vol" ]

check_criterion "init-second mounts work-vol" \
  [ "$(kget pod ordered-init-app '{.spec.initContainers[?(@.name=="init-second")].volumeMounts[?(@.name=="work-vol")].name}' -n "$QUESTION_ID")" = "work-vol" ]

INIT_SECOND_CMD="$(kget pod ordered-init-app '{.spec.initContainers[?(@.name=="init-second")].command}' -n "$QUESTION_ID")$(kget pod ordered-init-app '{.spec.initContainers[?(@.name=="init-second")].args}' -n "$QUESTION_ID")"
check_criterion "init-second command checks for first-done marker" \
  bash -c "echo '$INIT_SECOND_CMD' | grep -q first-done"

check_criterion "main container 'main' present with busybox image" \
  [ "$(kget pod ordered-init-app '{.spec.containers[?(@.name=="main")].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "main container mounts work-vol at /work" \
  [ "$(kget pod ordered-init-app '{.spec.containers[?(@.name=="main")].volumeMounts[?(@.name=="work-vol")].mountPath}' -n "$QUESTION_ID")" = "/work" ]

print_score
