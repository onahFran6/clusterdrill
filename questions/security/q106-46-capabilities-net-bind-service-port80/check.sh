#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q106-46-capabilities-net-bind-service-port80${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled together: Ready=true is the functional proof the capability
# actually works (the container is still non-root - without
# NET_BIND_SERVICE, binding port 80 fails and the readinessProbe never
# passes), so on its own "still runs as UID 1000" would be vacuously true
# right out of setup.sh (the crash-looping container is still non-root).
check_criterion "Pod 'privileged-port-listener' is Ready and still runs as non-root (runAsUser=1000)" \
  bash -c '
    ready="$(kubectl get pod privileged-port-listener -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Ready\")].status}" 2>/dev/null)"
    [ "$ready" = "True" ] || exit 1
    uid="$(kubectl get pod privileged-port-listener -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.securityContext.runAsUser}" 2>/dev/null)"
    [ "$uid" = "1000" ]
  '

check_criterion "Container 'listener' adds only NET_BIND_SERVICE and still drops ALL" \
  bash -c '
    added="$(kubectl get pod privileged-port-listener -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].securityContext.capabilities.add[*]}" 2>/dev/null)"
    dropped="$(kubectl get pod privileged-port-listener -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].securityContext.capabilities.drop[*]}" 2>/dev/null)"
    echo "$added" | grep -qw NET_BIND_SERVICE || exit 1
    [ "$(echo "$added" | wc -w | tr -d '[:space:]')" = "1" ] || exit 1
    echo "$dropped" | grep -qw ALL
  '

print_score
