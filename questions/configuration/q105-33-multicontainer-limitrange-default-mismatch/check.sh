#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-33-multicontainer-limitrange-default-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Give the pod a chance to settle before grading readiness.
kubectl wait --for=condition=Ready pod/worker -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1

# setup.sh never applies 'worker' - only the candidate does - so pod
# existence alone is already a valid pre-solve-false criterion here.
check_criterion "Pod 'worker' exists and both containers are Ready" \
  bash -c "
    phase=\$(kubectl get pod worker -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)
    [ \"\$phase\" = 'Running' ] || exit 1
    ready_count=\$(kubectl get pod worker -n '$QUESTION_ID' -o jsonpath='{range .status.containerStatuses[*]}{.ready}{\"\n\"}{end}' 2>/dev/null | grep -c '^true$')
    [ \"\$ready_count\" = '2' ]
  "

check_criterion "Container 'collector' inherited the LimitRange defaults: memory limit 128Mi and request 64Mi" \
  bash -c "
    lim=\$(kubectl get pod worker -n '$QUESTION_ID' -o jsonpath='{.spec.containers[?(@.name==\"collector\")].resources.limits.memory}' 2>/dev/null)
    [ \"\$lim\" = '128Mi' ] || exit 1
    req=\$(kubectl get pod worker -n '$QUESTION_ID' -o jsonpath='{.spec.containers[?(@.name==\"collector\")].resources.requests.memory}' 2>/dev/null)
    [ \"\$req\" = '64Mi' ]
  "

# Bundled on purpose: the LimitRange's own default/defaultRequest values
# are already correct and untouched right after setup.sh, so that fact
# alone is trivially true before any fix - it is folded into this same
# criterion (with shipper's still-wrong 256Mi request pre-fix) rather than
# scored standalone, so nothing here passes until the candidate actually
# adds shipper's explicit 64Mi request.
check_criterion "Container 'shipper' explicitly requests 64Mi memory while keeping its 256Mi limit, and the namespace LimitRange itself is unmodified" \
  bash -c "
    lim=\$(kubectl get pod worker -n '$QUESTION_ID' -o jsonpath='{.spec.containers[?(@.name==\"shipper\")].resources.limits.memory}' 2>/dev/null)
    [ \"\$lim\" = '256Mi' ] || exit 1
    req=\$(kubectl get pod worker -n '$QUESTION_ID' -o jsonpath='{.spec.containers[?(@.name==\"shipper\")].resources.requests.memory}' 2>/dev/null)
    [ \"\$req\" = '64Mi' ] || exit 1
    lr_default=\$(kubectl get limitrange container-mem-defaults -n '$QUESTION_ID' -o jsonpath='{.spec.limits[0].default.memory}' 2>/dev/null)
    [ \"\$lr_default\" = '128Mi' ] || exit 1
    lr_defreq=\$(kubectl get limitrange container-mem-defaults -n '$QUESTION_ID' -o jsonpath='{.spec.limits[0].defaultRequest.memory}' 2>/dev/null)
    [ \"\$lr_defreq\" = '64Mi' ]
  "

print_score
