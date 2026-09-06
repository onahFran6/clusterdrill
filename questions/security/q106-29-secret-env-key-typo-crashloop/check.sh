#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-29-secret-env-key-typo-crashloop${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Give the Pod a chance to settle (either it stays broken with
# CreateContainerConfigError, or the candidate's fix lets it start).
kubectl wait --for=condition=Ready pod/billing-worker -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1

# Bundled on purpose: right after setup.sh, the Pod exists but is NOT
# Running (CreateContainerConfigError), so the Running check alone is
# false in the unsolved state. The Secret-keys-unchanged and
# image-unchanged facts ARE trivially true right after setup.sh, so they
# are folded into this same criterion (not scored standalone) - nothing
# here scores until the candidate both (a) fixes the key reference so the
# container can actually start, AND (b) does so without touching the
# Secret's keys or swapping the image.
check_criterion "Pod 'billing-worker' is Running (busybox:1.36, db-creds keys intact) and DB_PASS matches Secret's 'password' key" \
  bash -c "
    phase=\$(kubectl get pod billing-worker -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)
    [ \"\$phase\" = 'Running' ] || exit 1
    image=\$(kubectl get pod billing-worker -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
    [ \"\$image\" = 'busybox:1.36' ] || exit 1
    username=\$(kubectl get secret db-creds -n '$QUESTION_ID' -o jsonpath='{.data.username}' 2>/dev/null | base64 -d)
    [ \"\$username\" = 'billing-app' ] || exit 1
    secret_pass=\$(kubectl get secret db-creds -n '$QUESTION_ID' -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)
    [ \"\$secret_pass\" = 's3cr3t-db-pass' ] || exit 1
    env_pass=\$(kubectl exec billing-worker -n '$QUESTION_ID' -- printenv DB_PASS 2>/dev/null)
    [ -n \"\$secret_pass\" ] && [ \"\$env_pass\" = \"\$secret_pass\" ]
  "

print_score
