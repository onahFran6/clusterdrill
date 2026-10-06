#!/usr/bin/env bash
# Spec-only checks, same rationale as every other Ingress question in this
# bank: this cluster has no Ingress controller installed, so only the
# object's final fields are asserted, never a live HTTP response.
set -uo pipefail

QUESTION_ID="q113-13-ingress-three-faults${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Ingress 'portal' has ingressClassName nginx" \
  [ "$(kget ingress portal '{.spec.ingressClassName}' -n "$QUESTION_ID")" = "nginx" ]

check_criterion "Ingress 'portal' rule backend names Service 'portal-svc'" \
  [ "$(kget ingress portal '{.spec.rules[0].http.paths[0].backend.service.name}' -n "$QUESTION_ID")" = "portal-svc" ]

check_criterion "Ingress 'portal' rule backend port is 80" \
  [ "$(kget ingress portal '{.spec.rules[0].http.paths[0].backend.service.port.number}' -n "$QUESTION_ID")" = "80" ]

print_score
