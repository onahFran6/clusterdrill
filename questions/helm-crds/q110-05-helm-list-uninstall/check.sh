#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-05-helm-list-uninstall${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# 'worker-a' still existing is trivially true right after setup.sh (it's
# never touched), so it can't be its own criterion - only "worker-b is gone
# AND worker-a is untouched" together prove the candidate did the right,
# selective uninstall rather than e.g. deleting the whole namespace.
B_GONE="no"
if ! helm status worker-b -n "$QUESTION_ID" >/dev/null 2>&1; then
  B_GONE="yes"
fi
check_criterion "Release 'worker-b' no longer exists in $QUESTION_ID" \
  [ "$B_GONE" = "yes" ]

B_DEPLOYMENT_GONE="no"
if ! kubectl get deployment worker-b-worker -n "$QUESTION_ID" >/dev/null 2>&1; then
  B_DEPLOYMENT_GONE="yes"
fi
check_criterion "Deployment 'worker-b-worker' was removed" \
  [ "$B_DEPLOYMENT_GONE" = "yes" ]

A_STILL_RUNNING="no"
if helm status worker-a -n "$QUESTION_ID" >/dev/null 2>&1 && \
   [ "$(kget deployment worker-a-worker '{.status.availableReplicas}' -n "$QUESTION_ID")" = "1" ]; then
  A_STILL_RUNNING="yes"
fi
SELECTIVE_UNINSTALL="no"
if [ "$A_STILL_RUNNING" = "yes" ] && [ "$B_GONE" = "yes" ]; then
  SELECTIVE_UNINSTALL="yes"
fi
check_criterion "Release 'worker-a' was left installed and running (selective uninstall, not a wipe)" \
  [ "$SELECTIVE_UNINSTALL" = "yes" ]

print_score
