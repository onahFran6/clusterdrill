#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-11-helm-chart-with-crd${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

CRD_NAME="cakes.bakery.clusterdrill.io"

check_criterion "CRD '$CRD_NAME' was installed by the chart" \
  resource_exists crd "$CRD_NAME"

check_criterion "CRD carries the clusterdrill-question label from the chart's crds/ manifest" \
  [ "$(kget crd "$CRD_NAME" '{.metadata.labels.clusterdrill-question}')" = "$QUESTION_ID" ]

check_criterion "Release 'batch1' is deployed" \
  helm status batch1 -n "$QUESTION_ID"

check_criterion "Cake instance 'batch1-cake' exists in $QUESTION_ID" \
  resource_exists cake batch1-cake -n "$QUESTION_ID"

check_criterion "Cake instance 'batch1-cake' has spec.flavor=vanilla" \
  [ "$(kget cake batch1-cake '{.spec.flavor}' -n "$QUESTION_ID")" = "vanilla" ]

print_score
