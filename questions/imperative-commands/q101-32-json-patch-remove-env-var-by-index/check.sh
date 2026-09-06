#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q101-32-json-patch-remove-env-var-by-index${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh already creates 'api-worker' Running/Ready with FIVE env vars, so
# "pod exists and is healthy" alone would trivially pass pre-solve. Bundled
# here with "exactly four env vars" (only true once LEGACY_API_URL is
# actually removed) so nothing scores until the candidate acts.
# Note: bash -c below spawns a fresh shell that doesn't inherit sourced
# functions like kget, so kubectl is invoked directly with -o jsonpath.
check_criterion "Pod 'api-worker' exists, is Running and Ready, with exactly 4 env vars" \
  bash -c "
    [ \"\$(kubectl get pod api-worker -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ] &&
    [ \"\$(kubectl get pod api-worker -n '$QUESTION_ID' -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)\" = 'true' ] &&
    [ \"\$(kubectl get pod api-worker -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].env[*].name}' 2>/dev/null | wc -w | tr -d ' ')\" = '4' ]
  "

# Exact-match the full ordered name=value dump against the expected
# post-fix list in one shot - this simultaneously proves order was kept,
# no value drifted, and no stray extra variable (e.g. LEGACY_API_URL with
# an empty string instead of being truly removed) snuck in, since any of
# those would break the exact string comparison.
check_criterion "Remaining env vars keep original order/names/values: APP_ENV=production, LOG_LEVEL=info, MAX_RETRIES=5, CACHE_TTL=300" \
  bash -c "
    expected=\$'APP_ENV=production\nLOG_LEVEL=info\nMAX_RETRIES=5\nCACHE_TTL=300'
    actual=\"\$(kubectl get pod api-worker -n '$QUESTION_ID' -o jsonpath='{range .spec.containers[0].env[*]}{.name}={.value}{\"\n\"}{end}' 2>/dev/null)\"
    [ \"\$actual\" = \"\$expected\" ]
  "

# Belt-and-suspenders on the specific failure mode the task calls out:
# LEGACY_API_URL must be truly absent from the env list, not merely
# present with its value blanked to an empty string (a jsonpath filter
# match on the name still succeeds in that case - only a fully removed
# array element makes this filter return nothing).
check_criterion "LEGACY_API_URL is completely absent from the env list (not just emptied)" \
  bash -c "
    [ -z \"\$(kubectl get pod api-worker -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].env[?(@.name==\"LEGACY_API_URL\")]}' 2>/dev/null)\" ]
  "

print_score
