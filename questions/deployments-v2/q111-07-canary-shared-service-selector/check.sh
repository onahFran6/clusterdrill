#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-07-canary-shared-service-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'shop-v2' runs nginx:1.27 with RELEASE=canary, 2/2 ready" \
  bash -c '
    image="$(kubectl get deployment shop-v2 -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    release="$(kubectl get deployment shop-v2 -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name==\"RELEASE\")].value}" 2>/dev/null)"
    ready="$(kubectl get deployment shop-v2 -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$image" = "nginx:1.27" ] && [ "$release" = "canary" ] && [ "$ready" = "2" ]
  '

check_criterion "Deployment 'shop-v1' scaled to 8 replicas" \
  [ "$(kget deployment shop-v1 '{.spec.replicas}' -n "$QUESTION_ID")" = "8" ]

check_criterion "Service 'shop' selector is app=shop only (no version key, so it matches both)" \
  bash -c '
    app="$(kubectl get service shop -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.app}" 2>/dev/null)"
    version="$(kubectl get service shop -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.version}" 2>/dev/null)"
    [ "$app" = "shop" ] && [ -z "$version" ]
  '

check_criterion "Service 'shop' has 10 endpoints total, spanning both v1 and v2 pods" \
  bash -c '
    version="$(kubectl get service shop -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.version}" 2>/dev/null)"
    [ -z "$version" ] || exit 1
    for _ in 1 2 3 4 5 6; do
      count="$(kubectl get endpointslices -l kubernetes.io/service-name=shop -n "'"$QUESTION_ID"'" \
        -o jsonpath="{range .items[*].endpoints[*]}{.addresses[0]}{\"\n\"}{end}" 2>/dev/null | grep -c .)"
      [ "$count" = "10" ] && exit 0
      sleep 1
    done
    exit 1
  '

print_score
