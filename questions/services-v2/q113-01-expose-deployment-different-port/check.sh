#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q113-01-expose-deployment-different-port${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'catalog-svc' exists, type ClusterIP" \
  bash -c "kubectl get service catalog-svc -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get service catalog-svc -n '$QUESTION_ID' -o jsonpath='{.spec.type}')\" = 'ClusterIP' ]"

check_criterion "Service 'catalog-svc' port 8080 targets containerPort 80" \
  bash -c "[ \"\$(kubectl get service catalog-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].port}')\" = '8080' ] && \
    [ \"\$(kubectl get service catalog-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].targetPort}')\" = '80' ]"

check_criterion "Service 'catalog-svc' selector matches the 'catalog' Deployment's pods" \
  bash -c "[ \"\$(kubectl get service catalog-svc -n '$QUESTION_ID' -o jsonpath='{.spec.selector.app}')\" = 'catalog' ]"

FQDN="catalog-svc.$QUESTION_ID.svc.cluster.local"
check_criterion "functional: requesting the Service's fully qualified DNS name on 8080 returns the nginx page" \
  bash -c "kubectl run tmp-q113-01-fn --rm -i --restart=Never --image=busybox:1.36 -n '$QUESTION_ID' -- \
    sh -c 'i=0; while [ \$i -lt 6 ]; do out=\$(wget -qO- -T 3 http://$FQDN:8080 2>/dev/null); \
    if echo \"\$out\" | grep -q \"<title>\"; then exit 0; fi; i=\$((i+1)); sleep 2; done; exit 1'"

print_score
