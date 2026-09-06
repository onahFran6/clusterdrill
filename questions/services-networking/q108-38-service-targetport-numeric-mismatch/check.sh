#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-38-service-targetport-numeric-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# "external port stays 80" is already true right before any fix is made
# (only targetPort is broken), so it is gated on the targetPort fix below
# to keep the unsolved state at 0 (lesson: vacuous-pass false positives).
TARGET_PORT="$(kget service media-worker-svc '{.spec.ports[0].targetPort}' -n "$QUESTION_ID")"
if [ "$TARGET_PORT" = "8080" ]; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "Service 'media-worker-svc' targetPort fixed to 8080" \
  [ "$FIXED" = "0" ]

check_criterion "Fix applied AND Service 'media-worker-svc' external port unchanged at 80" \
  bash -c "[ '$FIXED' = '0' ] && [ \"\$(kubectl get service media-worker-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].port}')\" = '80' ]"

check_criterion "Endpoints now target port 8080, matching the fixed targetPort" \
  bash -c '
    for _ in $(seq 1 15); do
      ep_port="$(kubectl get endpoints media-worker-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.subsets[*].ports[*].port}" 2>/dev/null)"
      [ "$ep_port" = "8080" ] && exit 0
      sleep 2
    done
    exit 1
  '

print_score
