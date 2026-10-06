#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a working ingress-nginx controller, so only the Ingress
# object's own fields are asserted here, never a live HTTP response.
set -uo pipefail

QUESTION_ID="q116-04-strip-the-prefix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Ingress 'legacy' exists in $QUESTION_ID" \
  resource_exists ingress legacy -n "$QUESTION_ID"

check_criterion "Ingress has use-regex=true and rewrite-target=/\$2 annotations" \
  bash -c "kubectl get ingress legacy -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '.metadata.annotations[\"nginx.ingress.kubernetes.io/use-regex\"] == \"true\" and .metadata.annotations[\"nginx.ingress.kubernetes.io/rewrite-target\"] == \"/\$2\"' >/dev/null"

check_criterion "Path is /legacy(/|\$)(.*), pathType ImplementationSpecific, backend legacy-svc:80" \
  bash -c "kubectl get ingress legacy -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.rules[0].http.paths[]? | select(.path == \"/legacy(/|\$)(.*)\" and .pathType == \"ImplementationSpecific\" and .backend.service.name == \"legacy-svc\" and .backend.service.port.number == 80)] | length == 1' >/dev/null"

print_score
