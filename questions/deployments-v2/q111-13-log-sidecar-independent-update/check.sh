#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-13-log-sidecar-independent-update${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "'log-shipper' sidecar added on busybox:1.37, 'app' left on busybox:1.36" \
  bash -c '
    app_image="$(kubectl get deployment orders -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[?(@.name==\"app\")].image}" 2>/dev/null)"
    shipper_image="$(kubectl get deployment orders -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[?(@.name==\"log-shipper\")].image}" 2>/dev/null)"
    [ "$app_image" = "busybox:1.36" ] && [ "$shipper_image" = "busybox:1.37" ]
  '

check_criterion "Both containers mount the same volume at /var/log/app" \
  bash -c '
    app_vol="$(kubectl get deployment orders -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[?(@.name==\"app\")].volumeMounts[?(@.mountPath==\"/var/log/app\")].name}" 2>/dev/null)"
    shipper_vol="$(kubectl get deployment orders -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[?(@.name==\"log-shipper\")].volumeMounts[?(@.mountPath==\"/var/log/app\")].name}" 2>/dev/null)"
    [ -n "$app_vol" ] && [ "$app_vol" = "$shipper_vol" ]
  '

check_criterion "log-shipper actually streams the orders log" \
  bash -c '
    for _ in 1 2 3 4 5 6; do
      pod="$(newest_pod_name "'"$QUESTION_ID"'" app=orders)"
      if [ -n "$pod" ] && kubectl logs "$pod" -n "'"$QUESTION_ID"'" -c log-shipper --tail=5 2>/dev/null | grep -q "order placed"; then
        exit 0
      fi
      sleep 1
    done
    exit 1
  '

print_score
