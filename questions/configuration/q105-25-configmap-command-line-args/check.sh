#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-25-configmap-command-line-args${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# The ConfigMap is never touched by setup.sh's broken pod, and "pod is
# Running" is also already true right after setup.sh (the starting container
# just sleeps) - on their own either check would violate the "unsolved state
# scores 0" gate. Bundle both into the same criterion as the one thing that
# actually changes (the logged output), so nothing here is true until the
# candidate has wired the env vars in from the untouched ConfigMap AND
# rewritten the command to actually echo them.
CM_GREETING="$(kget configmap greeter-config '{.data.GREETING}' -n "$QUESTION_ID")"
CM_TARGET="$(kget configmap greeter-config '{.data.TARGET}' -n "$QUESTION_ID")"
PHASE="$(kget pod greeter '{.status.phase}' -n "$QUESTION_ID")"

LOGS_OK="no"
if [ "$CM_GREETING" = "Hello" ] && [ "$CM_TARGET" = "World" ] && [ "$PHASE" = "Running" ]; then
  if kubectl logs greeter -n "$QUESTION_ID" 2>/dev/null | grep -qx "Hello World"; then
    LOGS_OK="yes"
  fi
fi
check_criterion "ConfigMap unchanged, pod 'greeter' Running, and 'kubectl logs greeter' contains the literal line 'Hello World'" \
  [ "$LOGS_OK" = "yes" ]

GREETING_KEY="$(kget pod greeter '{.spec.containers[0].env[?(@.name=="GREETING")].valueFrom.configMapKeyRef.key}' -n "$QUESTION_ID")"
TARGET_KEY="$(kget pod greeter '{.spec.containers[0].env[?(@.name=="TARGET")].valueFrom.configMapKeyRef.key}' -n "$QUESTION_ID")"
check_criterion "Pod 'greeter' sources env vars GREETING and TARGET from the greeter-config ConfigMap keys" \
  bash -c "[ '$GREETING_KEY' = 'GREETING' ] && [ '$TARGET_KEY' = 'TARGET' ]"

print_score
