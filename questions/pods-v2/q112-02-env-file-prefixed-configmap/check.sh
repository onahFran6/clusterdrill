#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-02-env-file-prefixed-configmap${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'shop-config' has exactly the 3 seeded keys/values" \
  bash -c '
    theme="$(kubectl get cm shop-config -n "'"$QUESTION_ID"'" -o jsonpath="{.data.THEME}" 2>/dev/null)"
    currency="$(kubectl get cm shop-config -n "'"$QUESTION_ID"'" -o jsonpath="{.data.CURRENCY}" 2>/dev/null)"
    cart="$(kubectl get cm shop-config -n "'"$QUESTION_ID"'" -o jsonpath="{.data.MAX_CART}" 2>/dev/null)"
    count="$(kubectl get cm shop-config -n "'"$QUESTION_ID"'" -o json 2>/dev/null | jq -r ".data | length")"
    [ "$theme" = "dark" ] && [ "$currency" = "NGN" ] && [ "$cart" = "25" ] && [ "$count" = "3" ]
  '

check_criterion "Pod 'shop' exists, image nginx:1.27" \
  [ "$(kget pod shop '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.27" ]

check_criterion "envFrom imports shop-config with prefix SHOP_" \
  bash -c '
    name="$(kubectl get pod shop -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].envFrom[0].configMapRef.name}" 2>/dev/null)"
    prefix="$(kubectl get pod shop -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].envFrom[0].prefix}" 2>/dev/null)"
    [ "$name" = "shop-config" ] && [ "$prefix" = "SHOP_" ]
  '

check_criterion "Pod is Running" \
  [ "$(kget pod shop '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

check_criterion "Exec into the Pod shows exactly SHOP_THEME/SHOP_CURRENCY/SHOP_MAX_CART" \
  bash -c '
    out="$(kubectl exec shop -n "'"$QUESTION_ID"'" -- sh -c "env | grep ^SHOP_ | sort" 2>/dev/null)"
    expected="$(printf "SHOP_CURRENCY=NGN\nSHOP_MAX_CART=25\nSHOP_THEME=dark")"
    [ "$out" = "$expected" ]
  '

print_score
