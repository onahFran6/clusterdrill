#!/usr/bin/env bash
# Idempotent: creates/resets namespace q106-34-aggregated-clusterrole-by-label
# and seeds an "aggregate" ClusterRole whose .rules stays empty until a
# candidate ClusterRole carrying the matching aggregation-selector label
# shows up. Every cluster-scoped object below
# carries clusterdrill-question=$QUESTION_ID so cleanup can find it - a
# namespace delete alone never touches ClusterRoles/ClusterRoleBindings.

set -euo pipefail

QUESTION_ID="q106-34-aggregated-clusterrole-by-label${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-reader
  labels:
    clusterdrill-question: $QUESTION_ID
EOF

# The aggregate ClusterRole: its .rules is deliberately empty. It only ever
# gains rules by the aggregation controller copying them in from any other
# ClusterRole that carries the label named in clusterRoleSelectors - and
# right now, nothing does.
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: q106-34-monitoring-aggregate
  labels:
    clusterdrill-question: $QUESTION_ID
aggregationRule:
  clusterRoleSelectors:
    - matchLabels:
        rbac.example.com/aggregate-to-q106-34-monitoring: "true"
rules: []
EOF

# Already bound cluster-wide to metrics-reader. The candidate must not
# touch this binding or the aggregate ClusterRole directly - only add a
# new, separately-labeled ClusterRole for the aggregation controller to
# fold in.
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: q106-34-monitoring-aggregate-binding
  labels:
    clusterdrill-question: $QUESTION_ID
subjects:
  - kind: ServiceAccount
    name: metrics-reader
    namespace: $QUESTION_ID
roleRef:
  kind: ClusterRole
  name: q106-34-monitoring-aggregate
  apiGroup: rbac.authorization.k8s.io
EOF

echo "setup.sh: $QUESTION_ID ready"
