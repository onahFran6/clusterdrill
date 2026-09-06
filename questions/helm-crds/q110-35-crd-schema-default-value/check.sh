#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-35-crd-schema-default-value${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

CRD_NAME="queues.jobs.clusterdrill.io"

DEFAULT_VALUE="$(kget crd "$CRD_NAME" '{.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.priority.default}')"
if [ "$DEFAULT_VALUE" = "5" ]; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "CRD schema sets default: 5 on spec.priority" \
  [ "$FIXED" = "0" ]

check_criterion "Fix applied AND spec.priority is still optional (not added to required)" \
  bash -c "[ '$FIXED' = '0' ] && ! kubectl get crd '$CRD_NAME' -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.spec.required}' | grep -q priority"

check_criterion "Queue 'batch-job' exists in $QUESTION_ID" \
  resource_exists queue batch-job -n "$QUESTION_ID"

check_criterion "Queue 'batch-job' spec.name is 'batch-job'" \
  [ "$(kget queue batch-job '{.spec.name}' -n "$QUESTION_ID")" = "batch-job" ]

check_criterion "Queue 'batch-job' spec.priority was defaulted to 5 (never set by hand)" \
  [ "$(kget queue batch-job '{.spec.priority}' -n "$QUESTION_ID")" = "5" ]

print_score
