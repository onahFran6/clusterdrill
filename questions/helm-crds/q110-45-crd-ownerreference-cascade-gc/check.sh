#!/usr/bin/env bash
# The candidate is told not to delete anything themselves - grading itself
# deletes the owner to observe real cascade-GC behavior. This is
# deliberate: if the candidate were graded on "both objects are gone" after
# doing the deletion themselves, manually deleting both by hand (without
# ever wiring up ownerReferences) would score identically to a real fix.
#
# The deletion below is gated behind the ownerReferences check actually
# passing first: check.sh runs twice in verify-question.sh (once expecting
# 0, once expecting full marks) - if it deleted 'nightly' unconditionally,
# the FIRST (unsolved) run would destroy the very object ANSWER.md needs
# to look up afterward, corrupting the second (solved) run before it ever
# gets a chance.
set -uo pipefail

QUESTION_ID="q110-45-crd-ownerreference-cascade-gc${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

PARENT_UID="$(kget backupset nightly '{.metadata.uid}' -n "$QUESTION_ID")"
OWNER_KIND="$(kget configmap nightly-manifest '{.metadata.ownerReferences[0].kind}' -n "$QUESTION_ID")"
OWNER_NAME="$(kget configmap nightly-manifest '{.metadata.ownerReferences[0].name}' -n "$QUESTION_ID")"
OWNER_UID="$(kget configmap nightly-manifest '{.metadata.ownerReferences[0].uid}' -n "$QUESTION_ID")"
OWNER_APIVERSION="$(kget configmap nightly-manifest '{.metadata.ownerReferences[0].apiVersion}' -n "$QUESTION_ID")"

if [ "$OWNER_KIND" = "BackupSet" ] && [ "$OWNER_NAME" = "nightly" ] && \
   [ "$OWNER_APIVERSION" = "ops.clusterdrill.io/v1" ] && \
   [ -n "$PARENT_UID" ] && [ "$OWNER_UID" = "$PARENT_UID" ]; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "ConfigMap 'nightly-manifest' has an ownerReference pointing at BackupSet 'nightly' with its real UID" \
  [ "$FIXED" = "0" ]

check_criterion "Fix applied AND both objects were left in place (not pre-emptively deleted by hand)" \
  bash -c "[ '$FIXED' = '0' ] && \
    kubectl get backupset nightly -n '$QUESTION_ID' >/dev/null 2>&1 && \
    kubectl get configmap nightly-manifest -n '$QUESTION_ID' >/dev/null 2>&1"

# Only reached once the fix is confirmed - never runs during the unsolved
# check, so it can't destroy state the reference answer still needs.
if [ "$FIXED" = "0" ]; then
  kubectl delete backupset nightly -n "$QUESTION_ID" --wait=true >/dev/null 2>&1
fi

check_criterion "Fix applied AND ConfigMap 'nightly-manifest' was cascade-deleted once its owner was removed" \
  bash -c '
    [ "'"$FIXED"'" = "0" ] || exit 1
    for _ in $(seq 1 15); do
      kubectl get configmap nightly-manifest -n "'"$QUESTION_ID"'" >/dev/null 2>&1 || exit 0
      sleep 2
    done
    exit 1
  '

print_score
