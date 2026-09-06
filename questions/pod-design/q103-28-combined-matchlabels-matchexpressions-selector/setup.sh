#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds seven pods with a mix of
# `tier` and `env` labels so that neither a `tier=worker`-only selector nor
# an `env in (staging,prod)`-only selector alone yields the correct set -
# only the combined equality+set-based selector does.

set -euo pipefail

QUESTION_ID="q103-28-combined-matchlabels-matchexpressions-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# name:tier:env
# worker-staging and worker-prod/worker-prod-2 are the correct answer set.
# worker-dev and worker-test are decoys: tier=worker but env NOT in
# (staging,prod) - a naive `-l tier=worker` selector alone would wrongly
# include them.
# web-staging and web-prod are decoys: env in (staging,prod) but tier!=worker
# - a naive `-l 'env in (staging,prod)'` selector alone would wrongly
# include them.
for spec in \
  "worker-staging:worker:staging" \
  "worker-prod:worker:prod" \
  "worker-prod-2:worker:prod" \
  "worker-dev:worker:dev" \
  "worker-test:worker:test" \
  "web-staging:web:staging" \
  "web-prod:web:prod"
do
  IFS=':' read -r name tier env <<< "$spec"
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $name
  labels:
    tier: $tier
    env: $env
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: $name
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF
done

echo "setup.sh: $QUESTION_ID ready"
