#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-31-serviceaccount-token-projection-audience${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl wait --for=condition=Ready pod/secrets-agent -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1

check_criterion "Pod 'secrets-agent' has automountServiceAccountToken=false" \
  bash -c "[ \"\$(kubectl get pod secrets-agent -n '$QUESTION_ID' -o jsonpath='{.spec.automountServiceAccountToken}' 2>/dev/null)\" = 'false' ]"

check_criterion "Pod has a projected volume mounted at /var/run/secrets/tokens with a serviceAccountToken source (audience=vault, expirationSeconds=600, path=vault-token)" \
  bash -c "
    mount_name=\$(kubectl get pod secrets-agent -n '$QUESTION_ID' \
      -o jsonpath='{.spec.containers[0].volumeMounts[?(@.mountPath==\"/var/run/secrets/tokens\")].name}' 2>/dev/null)
    [ -n \"\$mount_name\" ] || exit 1
    vol_json=\$(kubectl get pod secrets-agent -n '$QUESTION_ID' \
      -o jsonpath=\"{.spec.volumes[?(@.name==\\\"\$mount_name\\\")].projected}\" 2>/dev/null)
    [ -n \"\$vol_json\" ] || exit 1
    echo \"\$vol_json\" | grep -q '\"audience\":\"vault\"' \
      && echo \"\$vol_json\" | grep -q '\"expirationSeconds\":600' \
      && echo \"\$vol_json\" | grep -q '\"path\":\"vault-token\"'
  "

check_criterion "Pod is Running and 'kubectl exec ... ls /var/run/secrets/tokens' shows file 'vault-token'" \
  bash -c "
    phase=\$(kubectl get pod secrets-agent -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)
    [ \"\$phase\" = 'Running' ] || exit 1
    out=\$(kubectl exec secrets-agent -n '$QUESTION_ID' -- ls /var/run/secrets/tokens 2>/dev/null)
    echo \"\$out\" | grep -q '^vault-token\$'
  "

print_score
