#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-23-detect-progress-deadline-exceeded${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# No standalone "image untouched" criterion: setup.sh already leaves the
# Deployment on the bad image, so that alone would trivially pass on the
# unsolved state. The intent (candidate must not "fix" the image instead of
# diagnosing it) is still enforced below - if they touched it, the
# Progressing condition's reason would no longer be ProgressDeadlineExceeded.
check_criterion "Pod 'checker' exists with restartPolicy Never and image busybox:1.36" \
  bash -c '
    restart_policy="$(kubectl get pod checker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.restartPolicy}" 2>/dev/null)"
    image="$(kubectl get pod checker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    [ "$restart_policy" = "Never" ] && [ "$image" = "busybox:1.36" ]
  '

check_criterion "Pod 'checker' /tmp/deadline-reason.txt records the Deployment's actual Progressing reason (ProgressDeadlineExceeded)" \
  bash -c '
    actual_reason="$(kubectl get deployment report-generator -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Progressing\")].reason}" 2>/dev/null)"
    recorded="$(kubectl exec -n "'"$QUESTION_ID"'" checker -- cat /tmp/deadline-reason.txt 2>/dev/null)"
    [ "$actual_reason" = "ProgressDeadlineExceeded" ] \
      && echo "$recorded" | grep -q "ProgressDeadlineExceeded"
  '

print_score
