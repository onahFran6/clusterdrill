#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-18-rotate-a-secret-watch-it-land${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret api-token's decoded value is v2" \
  bash -c '
    b64="$(kubectl get secret api-token -n "'"$QUESTION_ID"'" -o jsonpath="{.data.value}" 2>/dev/null)"
    [ -n "$b64" ] || exit 1
    [ "$(echo "$b64" | base64 -d)" = "v2" ]
  '

# Bundled on purpose: a long-lived unsolved pod would eventually rack up
# plenty of /audit/log lines on its own, with no rotation at all - only
# requiring env/file to ALSO read v2 (which never happens without the
# candidate's own rotation+restart) keeps the line-count check from being
# satisfied by mere elapsed time.
check_criterion "Rotated to v2 end-to-end (env+file) AND /audit/log kept accumulating across the restart" \
  bash -c '
    for i in $(seq 1 15); do
      env_val="$(kubectl exec deploy/api -n "'"$QUESTION_ID"'" -- sh -c "echo \$TOKEN" 2>/dev/null)"
      file_val="$(kubectl exec deploy/api -n "'"$QUESTION_ID"'" -- cat /etc/token/value 2>/dev/null)"
      count="$(kubectl exec deploy/api -n "'"$QUESTION_ID"'" -- wc -l /audit/log 2>/dev/null | awk "{print \$1}")"
      if [ "$env_val" = "v2" ] && [ "$file_val" = "v2" ] && [ -n "$count" ] && [ "$count" -ge 3 ]; then
        exit 0
      fi
      sleep 4
    done
    exit 1
  '

print_score
