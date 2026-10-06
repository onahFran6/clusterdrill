#!/usr/bin/env bash
# Spec-only checks, same rationale as every other NetworkPolicy question in
# this bank: this cluster's default CNI does not enforce NetworkPolicy, so
# only the object's spec is asserted.
set -uo pipefail

QUESTION_ID="q113-16-egress-without-breaking-dns${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'backend-egress' selects app=backend, policyTypes [Egress], exactly 2 egress rules" \
  bash -c "kubectl get networkpolicy backend-egress -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get networkpolicy backend-egress -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'backend' ] && \
    [ \"\$(kubectl get networkpolicy backend-egress -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Egress\"]' ] && \
    [ \"\$(kubectl get networkpolicy backend-egress -n '$QUESTION_ID' -o jsonpath='{range .spec.egress[*]}x{end}')\" = 'xx' ]"

check_criterion "one egress rule allows TCP 5432 to app=db pods only" \
  bash -c "
    for i in 0 1; do
      app=\$(kubectl get networkpolicy backend-egress -n '$QUESTION_ID' -o jsonpath=\"{.spec.egress[\$i].to[0].podSelector.matchLabels.app}\" 2>/dev/null)
      nss=\$(kubectl get networkpolicy backend-egress -n '$QUESTION_ID' -o jsonpath=\"{.spec.egress[\$i].to[0].namespaceSelector}\" 2>/dev/null)
      ports=\$(kubectl get networkpolicy backend-egress -n '$QUESTION_ID' -o jsonpath=\"{.spec.egress[\$i].ports[0].protocol}:{.spec.egress[\$i].ports[0].port}\" 2>/dev/null)
      if [ \"\$app\" = 'db' ] && [ -z \"\$nss\" ] && [ \"\$ports\" = 'TCP:5432' ]; then exit 0; fi
    done
    exit 1
  "

check_criterion "one egress rule AND-combines namespaceSelector kube-system with podSelector k8s-app=kube-dns on UDP+TCP 53" \
  bash -c "
    for i in 0 1; do
      ns=\$(kubectl get networkpolicy backend-egress -n '$QUESTION_ID' -o jsonpath=\"{.spec.egress[\$i].to[0].namespaceSelector.matchLabels.kubernetes\.io/metadata\.name}\" 2>/dev/null)
      dns=\$(kubectl get networkpolicy backend-egress -n '$QUESTION_ID' -o jsonpath=\"{.spec.egress[\$i].to[0].podSelector.matchLabels.k8s-app}\" 2>/dev/null)
      p0=\$(kubectl get networkpolicy backend-egress -n '$QUESTION_ID' -o jsonpath=\"{.spec.egress[\$i].ports[0].protocol}:{.spec.egress[\$i].ports[0].port}\" 2>/dev/null)
      p1=\$(kubectl get networkpolicy backend-egress -n '$QUESTION_ID' -o jsonpath=\"{.spec.egress[\$i].ports[1].protocol}:{.spec.egress[\$i].ports[1].port}\" 2>/dev/null)
      if [ \"\$ns\" = 'kube-system' ] && [ \"\$dns\" = 'kube-dns' ] && \
         { [ \"\$p0\" = 'UDP:53' ] || [ \"\$p1\" = 'UDP:53' ]; } && \
         { [ \"\$p0\" = 'TCP:53' ] || [ \"\$p1\" = 'TCP:53' ]; }; then exit 0; fi
    done
    exit 1
  "

print_score
