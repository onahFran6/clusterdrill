#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-31-downward-api-resource-fields-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Give the pod a chance to settle (either it stays not-Ready with the
# CONTAINER_MEM_LIMIT/readiness mismatch, or the candidate's fix lets both
# containers pass readiness).
kubectl wait --for=condition=Ready pod/sidecar-metrics -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1

# Bundled on purpose: right after setup.sh, both containers' actual memory
# limits (main=200Mi, metrics=64Mi) are already correct and untouched by the
# candidate - that fact alone is trivially true before any fix, so it is
# folded into this same criterion rather than scored standalone. The pod is
# NOT 2/2 Ready right after setup.sh (metrics' CONTAINER_MEM_LIMIT resolves
# to main's 200Mi, so /tmp/limit never matches METRICS_MEM_LIMIT's 64Mi and
# the readiness probe keeps failing) - nothing scores here until the
# candidate repoints CONTAINER_MEM_LIMIT's resourceFieldRef.containerName at
# metrics, without editing either container's resources.limits.
check_criterion "main=200Mi and metrics=64Mi memory limits unchanged, metrics' CONTAINER_MEM_LIMIT resolves to 64Mi, and Pod 'sidecar-metrics' is 2/2 Ready" \
  bash -c "
    main_limit=\$(kubectl get pod sidecar-metrics -n '$QUESTION_ID' -o jsonpath='{.spec.containers[?(@.name==\"main\")].resources.limits.memory}' 2>/dev/null)
    [ \"\$main_limit\" = '200Mi' ] || exit 1
    metrics_limit=\$(kubectl get pod sidecar-metrics -n '$QUESTION_ID' -o jsonpath='{.spec.containers[?(@.name==\"metrics\")].resources.limits.memory}' 2>/dev/null)
    [ \"\$metrics_limit\" = '64Mi' ] || exit 1
    container_name=\$(kubectl get pod sidecar-metrics -n '$QUESTION_ID' -o jsonpath='{.spec.containers[?(@.name==\"metrics\")].env[?(@.name==\"CONTAINER_MEM_LIMIT\")].valueFrom.resourceFieldRef.containerName}' 2>/dev/null)
    [ \"\$container_name\" = 'metrics' ] || exit 1
    env_val=\$(kubectl exec sidecar-metrics -c metrics -n '$QUESTION_ID' -- printenv CONTAINER_MEM_LIMIT 2>/dev/null)
    [ \"\$env_val\" = '64' ] || exit 1
    ready_count=\$(kubectl get pod sidecar-metrics -n '$QUESTION_ID' -o jsonpath='{range .status.containerStatuses[*]}{.ready}{\"\n\"}{end}' 2>/dev/null | grep -c '^true$')
    [ \"\$ready_count\" = '2' ]
  "

print_score
