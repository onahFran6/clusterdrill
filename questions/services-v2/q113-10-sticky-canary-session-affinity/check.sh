#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q113-10-sticky-canary-session-affinity${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'whoami' sessionAffinity ClientIP with a 600s timeout" \
  bash -c "[ \"\$(kubectl get service whoami -n '$QUESTION_ID' -o jsonpath='{.spec.sessionAffinity}')\" = 'ClientIP' ] && \
    [ \"\$(kubectl get service whoami -n '$QUESTION_ID' -o jsonpath='{.spec.sessionAffinityConfig.clientIP.timeoutSeconds}')\" = '600' ]"

check_criterion "functional: one client sending 10 sequential requests reaches exactly 1 distinct pod" \
  bash -c "kubectl run tmp-q113-10-fn --rm -i --restart=Never --image=busybox:1.36 -n '$QUESTION_ID' -- \
    sh -c 'attempt=0; while [ \$attempt -lt 5 ]; do \
    n=\$(for i in \$(seq 10); do wget -qO- -T 3 whoami 2>/dev/null; echo; done | sort -u | sed \"/^\$/d\" | wc -l); \
    if [ \"\$n\" = \"1\" ]; then exit 0; fi; attempt=\$((attempt+1)); sleep 2; done; exit 1'"

print_score
