#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-26-diagnose-crashloop-missing-secret-key${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Give the rollout a chance to settle (either it stays broken with
# CreateContainerConfigError, or the candidate's fix lets it start).
kubectl wait --for=condition=Available deployment/gateway -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1

# Bundled on purpose: right after setup.sh, the Secret already has exactly
# one key API_TOKEN with its original value, and the Deployment already
# exists - those facts are trivially true before the candidate does
# anything, so they are folded into this same criterion rather than scored
# standalone. The Deployment is NOT 1/1 ready right after setup.sh
# (CreateContainerConfigError), so nothing scores here until the candidate
# fixes the secretKeyRef.key so the container actually starts, without
# touching the Secret itself.
check_criterion "Secret 'api-secret' has exactly one key API_TOKEN (unchanged), Deployment 'gateway' is 1/1 ready, and the container's env var matches it" \
  bash -c "
    keys=\$(kubectl get secret api-secret -n '$QUESTION_ID' -o jsonpath='{range .data.*}x{end}' 2>/dev/null)
    [ \"\$keys\" = 'x' ] || exit 1
    secret_val=\$(kubectl get secret api-secret -n '$QUESTION_ID' -o jsonpath='{.data.API_TOKEN}' 2>/dev/null | base64 -d)
    [ \"\$secret_val\" = 'sample-token-value' ] || exit 1
    ready=\$(kubectl get deployment gateway -n '$QUESTION_ID' -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
    [ \"\$ready\" = '1' ] || exit 1
    pod=\$(kubectl get pod -n '$QUESTION_ID' -l app=gateway --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    [ -n \"\$pod\" ] || exit 1
    env_val=\$(kubectl exec \"\$pod\" -n '$QUESTION_ID' -- printenv API_TOKEN 2>/dev/null)
    [ -n \"\$secret_val\" ] && [ \"\$env_val\" = \"\$secret_val\" ]
  "

print_score
