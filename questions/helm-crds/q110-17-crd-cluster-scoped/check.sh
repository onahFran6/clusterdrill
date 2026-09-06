#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-17-crd-cluster-scoped${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

CRD_NAME="datacenters.infra.clusterdrill.io"

check_criterion "CRD '$CRD_NAME' exists" \
  resource_exists crd "$CRD_NAME"

check_criterion "CRD carries the clusterdrill-question label" \
  [ "$(kget crd "$CRD_NAME" '{.metadata.labels.clusterdrill-question}')" = "$QUESTION_ID" ]

check_criterion "CRD scope is Cluster" \
  [ "$(kget crd "$CRD_NAME" '{.spec.scope}')" = "Cluster" ]

check_criterion "DataCenter 'dc-east' exists cluster-wide" \
  resource_exists datacenter dc-east

check_criterion "DataCenter 'dc-east' has spec.region=us-east-1" \
  [ "$(kget datacenter dc-east '{.spec.region}')" = "us-east-1" ]

check_criterion "DataCenter 'dc-east' resolves the same object via -n $QUESTION_ID (proving cluster scope)" \
  bash -c '
    real_uid="$(kubectl get datacenter dc-east -o jsonpath="{.metadata.uid}" 2>/dev/null)"
    ns_uid="$(kubectl get datacenter dc-east -n "$0" -o jsonpath="{.metadata.uid}" 2>/dev/null)"
    [ -n "$real_uid" ] && [ "$real_uid" = "$ns_uid" ]
  ' "$QUESTION_ID"

print_score
