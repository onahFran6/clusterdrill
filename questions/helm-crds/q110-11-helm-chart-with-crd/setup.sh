#!/usr/bin/env bash
# Stages a chart that bundles a CRD in its crds/ directory (Helm's special,
# non-templated CRD install path - installed once, before any templates,
# and never upgraded by `helm upgrade` by design). Nothing about the CRD or
# a CR instance is pre-created here: the candidate's `helm install` is what
# must register the CRD and roll out the chart's CustomResource template.

set -euo pipefail

QUESTION_ID="q110-11-helm-chart-with-crd${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CHART_DIR="$SCRIPT_DIR/chart"
rm -rf "$CHART_DIR"
mkdir -p "$CHART_DIR/crds" "$CHART_DIR/templates"

cat > "$CHART_DIR/Chart.yaml" <<'EOF'
apiVersion: v2
name: bakery
description: A minimal chart bundling its own CRD, for CKAD Helm+CRD practice
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
flavor: vanilla
EOF

# Helm's crds/ convention: plain manifests, no templating, installed first
# and only on `helm install` (never re-applied on `helm upgrade`).
cat > "$CHART_DIR/crds/cake.yaml" <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: cakes.bakery.clusterdrill.io
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  group: bakery.clusterdrill.io
  scope: Namespaced
  names:
    plural: cakes
    singular: cake
    kind: Cake
    listKind: CakeList
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              required:
                - flavor
              properties:
                flavor:
                  type: string
EOF

cat > "$CHART_DIR/templates/cake-instance.yaml" <<EOF
apiVersion: bakery.clusterdrill.io/v1
kind: Cake
metadata:
  name: {{ .Release.Name }}-cake
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  flavor: {{ .Values.flavor }}
EOF

echo "setup.sh: $QUESTION_ID ready (chart with bundled CRD staged at $CHART_DIR)"
