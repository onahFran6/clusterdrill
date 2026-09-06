#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-24-crd-conversion-webhook-none-multi-version${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

CRD_NAME="reports.analytics.clusterdrill.io"

check_criterion "CRD has exactly two entries in .spec.versions (v1beta1, v1)" \
  bash -c "kubectl get crd \"$CRD_NAME\" -o json 2>/dev/null | \
    jq -e '.spec.versions | length == 2 and (map(.name) | sort == [\"v1\", \"v1beta1\"])' >/dev/null"

check_criterion "v1beta1 remains served=true and storage=true" \
  bash -c "kubectl get crd \"$CRD_NAME\" -o json 2>/dev/null | \
    jq -e '(.spec.versions | length == 2) and ([.spec.versions[] | select(.name==\"v1beta1\")] | length == 1) and (.spec.versions[] | select(.name==\"v1beta1\") | .served == true and .storage == true)' >/dev/null"

check_criterion "v1 is a new entry with served=true and storage=false" \
  bash -c "kubectl get crd \"$CRD_NAME\" -o json 2>/dev/null | \
    jq -e '(.spec.versions | length == 2) and ([.spec.versions[] | select(.name==\"v1\")] | length == 1) and (.spec.versions[] | select(.name==\"v1\") | .served == true and .storage == false)' >/dev/null"

check_criterion "v1 schema requires spec.title as a string (matching v1beta1)" \
  bash -c "kubectl get crd \"$CRD_NAME\" -o json 2>/dev/null | \
    jq -e '(.spec.versions | length == 2) and (.spec.versions[] | select(.name==\"v1\") | .schema.openAPIV3Schema.properties.spec.required // [] | index(\"title\") != null)' >/dev/null && \
    kubectl get crd \"$CRD_NAME\" -o json 2>/dev/null | \
    jq -e '.spec.versions[] | select(.name==\"v1\") | .schema.openAPIV3Schema.properties.spec.properties.title.type == \"string\"' >/dev/null"

check_criterion "conversion strategy is still None (or unset/default) with two versions present" \
  bash -c "count=\$(kubectl get crd \"$CRD_NAME\" -o jsonpath='{.spec.versions[*].name}' 2>/dev/null | wc -w | tr -d ' '); \
    strategy=\$(kubectl get crd \"$CRD_NAME\" -o jsonpath='{.spec.conversion.strategy}' 2>/dev/null); \
    [ \"\$count\" = \"2\" ] && { [ -z \"\$strategy\" ] || [ \"\$strategy\" = \"None\" ]; }"

check_criterion "Report 'q3-summary' still exists unchanged, readable via v1beta1 path, with two CRD versions present" \
  bash -c "count=\$(kubectl get crd \"$CRD_NAME\" -o jsonpath='{.spec.versions[*].name}' 2>/dev/null | wc -w | tr -d ' '); \
    title=\$(kubectl get reports.v1beta1.analytics.clusterdrill.io q3-summary -n \"$QUESTION_ID\" -o jsonpath='{.spec.title}' 2>/dev/null); \
    [ \"\$count\" = \"2\" ] && [ \"\$title\" = \"Q3 Summary\" ]"

check_criterion "Report 'q3-summary' is retrievable via the new v1 API path with the same spec.title" \
  bash -c "kubectl get reports.v1.analytics.clusterdrill.io q3-summary -n \"$QUESTION_ID\" -o jsonpath='{.spec.title}' 2>/dev/null | grep -qx 'Q3 Summary'"

print_score
