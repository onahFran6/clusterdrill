#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-43-crd-structural-schema-pruning${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

CRD_NAME="profiles.people.clusterdrill.io"

SCHEMA_TYPE="$(kget crd "$CRD_NAME" '{.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.timezone.type}')"
if [ "$SCHEMA_TYPE" = "string" ]; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "CRD 'profiles.people.clusterdrill.io' schema now declares spec.timezone (string)" \
  [ "$FIXED" = "0" ]

check_criterion "Fix applied AND Profile 'alice' spec.timezone actually persisted (not pruned)" \
  bash -c "[ '$FIXED' = '0' ] && [ \"\$(kubectl get profile alice -n '$QUESTION_ID' -o jsonpath='{.spec.timezone}')\" = 'America/New_York' ]"

check_criterion "Fix applied AND Profile 'alice' spec.displayName unchanged" \
  bash -c "[ '$FIXED' = '0' ] && [ \"\$(kubectl get profile alice -n '$QUESTION_ID' -o jsonpath='{.spec.displayName}')\" = 'Alice' ]"

print_score
