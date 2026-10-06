#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a working ingress-nginx controller, so only live object state
# is asserted here (IngressClass annotation, Ingress's resolved
# ingressClassName field), never a live HTTP response.
set -uo pipefail

QUESTION_ID="q116-05-the-default-class-came-too-late${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "IngressClass 'q116-05-ingress-class' is annotated as the default IngressClass" \
  [ "$(kget ingressclass q116-05-ingress-class '{.metadata.annotations.ingressclass\.kubernetes\.io/is-default-class}')" = "true" ]

# On a cluster where some other IngressClass was already marked default
# (common - e.g. minikube's own "ingress" addon), setup.sh's classless
# 'pulsar' Ingress gets that OTHER class baked in immediately at creation,
# before the candidate does anything - so this criterion is false on the
# fresh, unsolved state regardless of which cluster this runs against:
# either "pulsar" has no class at all yet, or it already has some other
# class, but never this question's own q116-05-ingress-class.
check_criterion "Ingress 'pulsar' resolved to IngressClass q116-05-ingress-class" \
  [ "$(kget ingress pulsar '{.spec.ingressClassName}' -n "$QUESTION_ID")" = "q116-05-ingress-class" ]

print_score
