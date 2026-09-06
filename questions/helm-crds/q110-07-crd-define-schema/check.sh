#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-07-crd-define-schema${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

CRD_NAME="coffeeorders.snacks.clusterdrill.io"

check_criterion "CRD '$CRD_NAME' exists" \
  resource_exists crd "$CRD_NAME"

check_criterion "CRD carries the clusterdrill-question label" \
  [ "$(kget crd "$CRD_NAME" '{.metadata.labels.clusterdrill-question}')" = "$QUESTION_ID" ]

check_criterion "CRD group is snacks.clusterdrill.io" \
  [ "$(kget crd "$CRD_NAME" '{.spec.group}')" = "snacks.clusterdrill.io" ]

check_criterion "CRD scope is Namespaced" \
  [ "$(kget crd "$CRD_NAME" '{.spec.scope}')" = "Namespaced" ]

check_criterion "CRD kind is CoffeeOrder" \
  [ "$(kget crd "$CRD_NAME" '{.spec.names.kind}')" = "CoffeeOrder" ]

check_criterion "CRD plural is coffeeorders" \
  [ "$(kget crd "$CRD_NAME" '{.spec.names.plural}')" = "coffeeorders" ]

check_criterion "CRD v1 version is served and is the storage version" \
  bash -c '
    served=$(kubectl get crd "$0" -o jsonpath="{.spec.versions[?(@.name==\"v1\")].served}" 2>/dev/null)
    storage=$(kubectl get crd "$0" -o jsonpath="{.spec.versions[?(@.name==\"v1\")].storage}" 2>/dev/null)
    [ "$served" = "true" ] && [ "$storage" = "true" ]
  ' "$CRD_NAME"

check_criterion "CRD v1 schema requires 'size' under spec" \
  bash -c '
    required=$(kubectl get crd "$0" -o jsonpath="{.spec.versions[?(@.name==\"v1\")].schema.openAPIV3Schema.properties.spec.required}" 2>/dev/null)
    echo "$required" | grep -q "size"
  ' "$CRD_NAME"

check_criterion "CRD v1 schema types 'size' as a string" \
  [ "$(kget crd "$CRD_NAME" '{.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.size.type}')" = "string" ]

print_score
