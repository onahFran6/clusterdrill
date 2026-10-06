#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q113-06-externalname-points-outside${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'payments' is ExternalName -> example.com, no ports" \
  bash -c "kubectl get service payments -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get service payments -n '$QUESTION_ID' -o jsonpath='{.spec.type}')\" = 'ExternalName' ] && \
    [ \"\$(kubectl get service payments -n '$QUESTION_ID' -o jsonpath='{.spec.externalName}')\" = 'example.com' ] && \
    [ -z \"\$(kubectl get service payments -n '$QUESTION_ID' -o jsonpath='{.spec.ports}')\" ]"

FQDN="payments.$QUESTION_ID.svc.cluster.local"
check_criterion "functional: DNS lookup of the Service's FQDN returns a CNAME naming example.com" \
  bash -c "kubectl run tmp-q113-06-fn --rm -i --restart=Never --image=busybox:1.36 -n '$QUESTION_ID' -- \
    sh -c 'i=0; while [ \$i -lt 6 ]; do out=\$(nslookup $FQDN 2>/dev/null); \
    if echo \"\$out\" | grep -q \"canonical name = example.com\"; then exit 0; fi; i=\$((i+1)); sleep 2; done; exit 1'"

print_score
