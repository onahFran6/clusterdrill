#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-17-permission-denied-on-the-volume${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled on purpose: pod-level runAsUser=1000/fsGroup=2000 are already
# true in the unsolved seed (nothing touches them yet) - only combined
# with "a root init container that chowns the claim actually exists" does
# this prove the candidate's own fix, not just an untouched baseline.
check_criterion "An init container runs as root and chowns the claim, while the main container stays non-root" \
  bash -c '
    init_count="$(kubectl get deployment uploader -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.initContainers}" 2>/dev/null)"
    [ -n "$init_count" ] && [ "$init_count" != "null" ] || exit 1
    uid="$(kubectl get deployment uploader -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.initContainers[0].securityContext.runAsUser}" 2>/dev/null)"
    cmd="$(kubectl get deployment uploader -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.initContainers[0].command}" 2>/dev/null)"
    mount="$(kubectl get deployment uploader -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.initContainers[0].volumeMounts[0].mountPath}" 2>/dev/null)"
    pod_u="$(kubectl get deployment uploader -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.securityContext.runAsUser}" 2>/dev/null)"
    pod_g="$(kubectl get deployment uploader -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.securityContext.fsGroup}" 2>/dev/null)"
    [ "$uid" = "0" ] && [ "$mount" = "/data" ] && echo "$cmd" | grep -q "chown" \
      && [ "$pod_u" = "1000" ] && [ "$pod_g" = "2000" ]
  '

check_criterion "Deployment uploader is Running with /data owned by uid 1000 and a low restart count" \
  bash -c '
    for i in $(seq 1 15); do
      ready="$(kubectl get deployment uploader -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
      if [ "$ready" = "1" ]; then
        owner="$(kubectl exec deploy/uploader -n "'"$QUESTION_ID"'" -- stat -c %u /data 2>/dev/null)"
        restarts="$(kubectl get pods -n "'"$QUESTION_ID"'" -l app=uploader -o jsonpath="{.items[0].status.containerStatuses[0].restartCount}" 2>/dev/null)"
        if [ "$owner" = "1000" ] && [ -n "$restarts" ] && [ "$restarts" -le 2 ]; then
          exit 0
        fi
      fi
      sleep 4
    done
    exit 1
  '

print_score
