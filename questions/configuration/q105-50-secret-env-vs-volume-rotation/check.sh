#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-50-secret-env-vs-volume-rotation${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'db-creds' PASSWORD = rotated-pw-99" \
  [ "$(kubectl get secret db-creds -n "$QUESTION_ID" -o jsonpath='{.data.PASSWORD}' 2>/dev/null | base64 -d 2>/dev/null)" = "rotated-pw-99" ]

# The volume-mounted value is checked in a retry loop (up to ~90s): kubelet
# syncs a Secret volume's content on its own periodic schedule ("roughly
# every minute" per the K8s docs, not a hard upper bound), so ANSWER.md's
# fixed sleep before this check runs isn't a guarantee it's landed yet - a
# single immediate read can be a false negative against a correct answer.
check_criterion "Pod 'credential-consumer' is still Running with 2/2 ready containers AND vol-reader's mounted /etc/secret/PASSWORD reflects the rotated value" \
  bash -c '
    phase="$(kubectl get pod credential-consumer -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Running" ] || exit 1
    ready_count="$(kubectl get pod credential-consumer -n "'"$QUESTION_ID"'" -o jsonpath="{range .status.containerStatuses[*]}{.ready}{\"\n\"}{end}" 2>/dev/null | grep -c true)"
    [ "$ready_count" = "2" ] || exit 1
    for _ in $(seq 1 30); do
      vol_pw="$(kubectl exec -n "'"$QUESTION_ID"'" credential-consumer -c vol-reader -- cat /etc/secret/PASSWORD 2>/dev/null)"
      [ "$vol_pw" = "rotated-pw-99" ] && exit 0
      sleep 3
    done
    exit 1
  '

# Bundled with the Secret actually being rotated (rather than standalone) -
# env-reader showing initial-pw is true both before AND after a correct
# rotation (that staleness is the whole point), so on its own this would
# never score 0 pre-solve. Requiring the rotation alongside it here is what
# makes the "still frozen" observation meaningful instead of coincidental.
check_criterion "The Secret was actually rotated AND env-reader's DB_PASSWORD stays frozen at the original value (initial-pw) - expected, not a bug" \
  bash -c '
    pw="$(kubectl get secret db-creds -n "'"$QUESTION_ID"'" -o jsonpath="{.data.PASSWORD}" 2>/dev/null | base64 -d 2>/dev/null)"
    [ "$pw" = "rotated-pw-99" ] || exit 1
    env_pw="$(kubectl exec -n "'"$QUESTION_ID"'" credential-consumer -c env-reader -- sh -c "echo \$DB_PASSWORD" 2>/dev/null)"
    [ "$env_pw" = "initial-pw" ]
  '

print_score
