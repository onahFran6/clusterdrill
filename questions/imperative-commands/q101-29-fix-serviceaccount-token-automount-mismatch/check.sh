#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-29-fix-serviceaccount-token-automount-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh already creates 'introspector' with serviceAccountName=default,
# automountServiceAccountToken=false, and image bitnami/kubectl:latest. The
# image alone is already correct pre-fix and the candidate never has a
# reason to change it, so it must never be graded on its own (that would be
# a trivially-true criterion before any real fix lands). Bundle SA name +
# automount flag + image into one criterion so nothing scores until the
# candidate actually deletes/recreates the pod with the right identity.
check_criterion "Pod 'introspector' runs as ServiceAccount 'reader-sa', does not disable token automount, and still runs image 'bitnami/kubectl:latest'" \
  bash -c '
    sa=$(kubectl get pod introspector -o jsonpath="{.spec.serviceAccountName}" -n "'"$QUESTION_ID"'" 2>/dev/null)
    [ "$sa" = "reader-sa" ] || exit 1
    automount=$(kubectl get pod introspector -o jsonpath="{.spec.automountServiceAccountToken}" -n "'"$QUESTION_ID"'" 2>/dev/null)
    [ "$automount" != "false" ] || exit 1
    image=$(kubectl get pod introspector -o jsonpath="{.spec.containers[0].image}" -n "'"$QUESTION_ID"'" 2>/dev/null)
    [ "$image" = "bitnami/kubectl:latest" ]
  '

# The real proof: exec into the pod itself and run the same command the
# candidate was told to fix. This only passes once the pod actually has a
# mounted reader-sa token AND the RBAC binding (already correct from
# setup.sh) grants it 'list pods'. Poll briefly since a freshly recreated
# pod needs a moment to reach Running/Ready.
introspector_can_list_pods() {
  local i phase
  for ((i = 0; i < 30; i++)); do
    phase="$(kubectl get pod introspector -n "$QUESTION_ID" -o jsonpath='{.status.phase}' 2>/dev/null)"
    if [ "$phase" = "Running" ]; then
      if kubectl exec introspector -n "$QUESTION_ID" -- kubectl auth can-i list pods 2>/dev/null | grep -q '^yes$'; then
        return 0
      fi
    fi
    sleep 2
  done
  return 1
}
check_criterion "'kubectl exec introspector -- kubectl auth can-i list pods' returns yes" \
  introspector_can_list_pods

print_score
