#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-20-move-to-a-bigger-claim${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC new-data exists, requesting 500Mi" \
  bash -c '[ "$(kubectl get pvc new-data -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.resources.requests.storage}" 2>/dev/null)" = "500Mi" ]'

# Bundled on purpose: old-data already has the files and archive is
# already Running in the unsolved baseline too - the volume actually
# pointing at new-data (not old-data) is the real discriminator that
# proves the migration happened.
check_criterion "Deployment archive's volume now references new-data, not old-data, and is Running with r1/r2/r3 present" \
  bash -c '
    for i in $(seq 1 10); do
      claim="$(kubectl get deployment archive -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}" 2>/dev/null)"
      ready="$(kubectl get deployment archive -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
      if [ "$claim" = "new-data" ] && [ "$ready" = "1" ]; then
        files="$(kubectl exec deploy/archive -n "'"$QUESTION_ID"'" -- ls /archive 2>/dev/null)"
        echo "$files" | grep -q "^r1$" && echo "$files" | grep -q "^r2$" && echo "$files" | grep -q "^r3$" && exit 0
      fi
      sleep 4
    done
    exit 1
  '

print_score
