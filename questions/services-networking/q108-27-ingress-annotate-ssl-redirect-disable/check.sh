#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-27-ingress-annotate-ssl-redirect-disable${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled into ONE criterion: setup.sh already creates the Ingress with no
# spec.tls AND with the correct docs-svc:80 backend, so either of those
# alone would be trivially true before the candidate does anything. Only the
# annotation flip to "false" is the real candidate action - but per the
# "unsolved state must score 0" gate, everything must live in a single
# check_criterion call keyed on the one thing that actually changes.
check_criterion "Ingress 'docs-ingress' has force-ssl-redirect=false, no spec.tls, and still routes to docs-svc:80" \
  bash -c "[ -z \"\$(kubectl get ingress docs-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.tls}' 2>/dev/null)\" ] && \
    [ \"\$(kubectl get ingress docs-ingress -n '$QUESTION_ID' -o jsonpath='{.metadata.annotations.nginx\\.ingress\\.kubernetes\\.io/force-ssl-redirect}' 2>/dev/null)\" = 'false' ] && \
    [ \"\$(kubectl get ingress docs-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}:{.spec.rules[0].http.paths[0].backend.service.port.number}' 2>/dev/null)\" = 'docs-svc:80' ]"

print_score
