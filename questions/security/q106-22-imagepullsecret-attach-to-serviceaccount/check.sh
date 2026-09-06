#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-22-imagepullsecret-attach-to-serviceaccount${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ServiceAccount 'builder' lists 'registry-creds' as an imagePullSecret AND the Secret is unchanged" \
  bash -c "[ \"\$(kubectl get sa builder -n '$QUESTION_ID' -o jsonpath='{.imagePullSecrets[*].name}' 2>/dev/null | tr ' ' '\n' | grep -c '^registry-creds\$')\" -ge 1 ] && \
    [ \"\$(kubectl get secret registry-creds -n '$QUESTION_ID' -o jsonpath='{.type}' 2>/dev/null)\" = 'kubernetes.io/dockerconfigjson' ]"

print_score
