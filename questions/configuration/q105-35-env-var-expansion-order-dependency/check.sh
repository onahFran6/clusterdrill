#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-35-env-var-expansion-order-dependency${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl wait --for=condition=Ready pod/path-builder -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1

# Bundled on purpose: right after setup.sh, REGION is already correctly
# wired via configMapKeyRef against region-config (that part was never
# broken) - checking that alone would be trivially true before the
# candidate touches anything, so it is folded into the same criterion as
# the thing that actually changes: whether ARCHIVE_PATH itself resolves to
# a real path instead of the literal, unexpanded string
# "$(BASE_DIR)/$(REGION)/archive" that setup.sh's wrong env-list order
# produces. Nothing scores here until BASE_DIR and REGION are both moved
# ahead of ARCHIVE_PATH in the env list (order only - same names/values/
# sources).
check_criterion "REGION still sourced from ConfigMap 'region-config' via configMapKeyRef, and ARCHIVE_PATH resolves to /data/eu-west-1/archive (not a literal placeholder)" \
  bash -c "
    cm_name=\$(kubectl get pod path-builder -n '$QUESTION_ID' -o jsonpath='{.spec.containers[?(@.name==\"builder\")].env[?(@.name==\"REGION\")].valueFrom.configMapKeyRef.name}' 2>/dev/null)
    cm_key=\$(kubectl get pod path-builder -n '$QUESTION_ID' -o jsonpath='{.spec.containers[?(@.name==\"builder\")].env[?(@.name==\"REGION\")].valueFrom.configMapKeyRef.key}' 2>/dev/null)
    [ \"\$cm_name\" = 'region-config' ] || exit 1
    [ \"\$cm_key\" = 'REGION' ] || exit 1
    archive_val=\$(kubectl exec path-builder -c builder -n '$QUESTION_ID' -- sh -c 'echo \$ARCHIVE_PATH' 2>/dev/null)
    [ \"\$archive_val\" = '/data/eu-west-1/archive' ]
  "

# Also bundled: this is the terminal value of the whole chain, only true
# once ARCHIVE_PATH (checked above) is itself fixed AND still precedes
# FINAL_PATH in the env list.
check_criterion "FINAL_PATH resolves to the fully composed path /data/eu-west-1/archive/current" \
  bash -c "
    final_val=\$(kubectl exec path-builder -c builder -n '$QUESTION_ID' -- sh -c 'echo \$FINAL_PATH' 2>/dev/null)
    [ \"\$final_val\" = '/data/eu-west-1/archive/current' ]
  "

print_score
