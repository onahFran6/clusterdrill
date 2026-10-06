#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q113-08-cross-namespace-dns${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'frontend' env BACKEND_URL no longer references the nonexistent 'pollux' namespace" \
  bash -c "val=\$(kubectl get deployment frontend -n '$QUESTION_ID' \
    -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name==\"BACKEND_URL\")].value}' 2>/dev/null); \
    echo \"\$val\" | grep -q 'backend' && ! echo \"\$val\" | grep -q 'pollux'"

check_criterion "functional: frontend's current logs show a successful call to backend, not 'call failed'" \
  bash -c "
    for i in 1 2 3 4 5 6 7 8; do
      pod=\$(newest_pod_name '$QUESTION_ID' app=frontend)
      if [ -n \"\$pod\" ]; then
        logs=\$(kubectl logs \"\$pod\" -n '$QUESTION_ID' --tail=5 2>/dev/null)
        if echo \"\$logs\" | grep -q 'backend says hi' && ! echo \"\$logs\" | tail -1 | grep -q 'call failed'; then
          exit 0
        fi
      fi
      sleep 3
    done
    exit 1
  "

print_score
