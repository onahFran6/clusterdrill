#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
#
# securityContext.seccompProfile is immutable on a running pod, so the
# reference solution deletes and recreates 'worker'. A just-recreated pod
# can briefly report .status.phase=Running while still Terminating, or
# still be starting up - poll for a settled Running/Ready state instead of
# trusting a single snapshot.
#
# Both criteria below bundle "pod is Running/Ready" (already true the
# instant setup.sh finishes, before the candidate touches anything) into
# the SAME check as the seccompProfile field (which setup.sh leaves unset),
# so neither criterion is trivially true in the unsolved state.
set -uo pipefail

QUESTION_ID="q106-32-seccomp-runtime-default${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

_phase=""
_ready=""
_image=""
_command=""
_seccomp_type=""

for _ in $(seq 1 24); do
  _phase="$(kget pod worker '{.status.phase}' -n "$QUESTION_ID")"
  _ready="$(kget pod worker '{.status.containerStatuses[0].ready}' -n "$QUESTION_ID")"
  if [ "$_phase" = "Running" ] && [ "$_ready" = "true" ]; then
    _image="$(kget pod worker '{.spec.containers[0].image}' -n "$QUESTION_ID")"
    _command="$(kget pod worker '{.spec.containers[0].command}' -n "$QUESTION_ID")"
    _seccomp_type="$(kget pod worker '{.spec.containers[0].securityContext.seccompProfile.type}' -n "$QUESTION_ID")"
    break
  fi
  sleep 5
done

check_criterion "Pod 'worker' is Running and Ready, and container 'worker's securityContext.seccompProfile.type is RuntimeDefault" \
  bash -c "[ '$_phase' = 'Running' ] && [ '$_ready' = 'true' ] && [ '$_seccomp_type' = 'RuntimeDefault' ]"

check_criterion "Pod 'worker' still runs image busybox:1.36 with command [\"sleep\",\"3600\"] unchanged, with seccompProfile.type RuntimeDefault" \
  bash -c "[ '$_image' = 'busybox:1.36' ] && [ '$_command' = '[\"sleep\",\"3600\"]' ] && [ '$_seccomp_type' = 'RuntimeDefault' ]"

print_score
