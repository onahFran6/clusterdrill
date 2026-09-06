#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-30-projected-volume-configmap-and-secret${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Give a recreated pod a chance to reach Ready before we sample it.
kubectl wait --for=condition=Ready pod/combiner -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1

# Bundled on purpose: right after setup.sh, the ConfigMap and Secret already
# exist with their original content untouched - that fact alone is trivially
# true before the candidate does anything, so it is folded into the same
# criterion as the pod actually being Running/Ready, which is NOT true right
# after setup.sh (the pod is stuck in ContainerCreating because the
# projected volume's sources reference names that don't exist). Nothing
# scores here until the candidate fixes the source names and the pod starts.
check_criterion "ConfigMap/Secret are unmodified and pod 'combiner' is Running and Ready" \
  bash -c "
    conf=\$(kubectl get configmap app-settings -n '$QUESTION_ID' -o jsonpath='{.data.app\.conf}' 2>/dev/null)
    [ \"\$conf\" = \$'mode=production\ncache=enabled' ] || exit 1
    secret_val=\$(kubectl get secret app-secret-key -n '$QUESTION_ID' -o jsonpath='{.data.secret\.key}' 2>/dev/null | base64 -d)
    [ \"\$secret_val\" = 'sample-secret-value' ] || exit 1
    phase=\$(kubectl get pod combiner -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)
    [ \"\$phase\" = 'Running' ] || exit 1
    ready=\$(kubectl get pod combiner -n '$QUESTION_ID' -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
    [ \"\$ready\" = 'true' ] || exit 1
  "

check_criterion "Pod 'combiner' has /etc/combined/app.conf with the ConfigMap's original content" \
  bash -c "
    got=\$(kubectl exec combiner -n '$QUESTION_ID' -- cat /etc/combined/app.conf 2>/dev/null)
    [ \"\$got\" = \$'mode=production\ncache=enabled' ]
  "

check_criterion "Pod 'combiner' has /etc/combined/secret.key with the Secret's original content" \
  bash -c "
    got=\$(kubectl exec combiner -n '$QUESTION_ID' -- cat /etc/combined/secret.key 2>/dev/null)
    [ \"\$got\" = 'sample-secret-value' ]
  "

print_score
