#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-41-projected-volume-merge-missing-key${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="combined-config-app"

# Pod is already 2/2 Running in the unsolved state (nothing crashes), so
# bundle the structural fix (db-pass added to the projected secret items)
# with Running into ONE criterion.
STRUCT_OK=0
for _ in $(seq 1 24); do
  DBPASS_KEY="$(kget pod "$POD" '{.spec.volumes[?(@.name=="combined")].projected.sources[1].secret.items[?(@.path=="db-pass")].key}' -n "$QUESTION_ID")"
  APIKEY_KEY="$(kget pod "$POD" '{.spec.volumes[?(@.name=="combined")].projected.sources[1].secret.items[?(@.path=="api-key")].key}' -n "$QUESTION_ID")"
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  READY_FLAGS="$(kget pod "$POD" '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID")"
  READY_COUNT="$(echo "$READY_FLAGS" | tr ' ' '\n' | grep -c '^true$' 2>/dev/null || true)"

  if [ "$DBPASS_KEY" = "db-pass" ] && [ "$APIKEY_KEY" = "api-key" ] \
     && [ "$PHASE" = "Running" ] && [ "$READY_COUNT" = "2" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 4
done
check_criterion "projected volume's Secret source items now include db-pass (api-key preserved), Pod 2/2 Running" \
  [ "$STRUCT_OK" = "1" ]

CONTENT_OK=0
for _ in $(seq 1 12); do
  APP_CONF="$(kubectl exec "$POD" -c app -n "$QUESTION_ID" -- cat /etc/combined/app.conf 2>/dev/null)"
  API_KEY="$(kubectl exec "$POD" -c app -n "$QUESTION_ID" -- cat /etc/combined/api-key 2>/dev/null)"
  DB_PASS="$(kubectl exec "$POD" -c app -n "$QUESTION_ID" -- cat /etc/combined/db-pass 2>/dev/null)"
  if [ "$APP_CONF" = "loglevel=info" ] && [ "$API_KEY" = "sek-4471" ] && [ "$DB_PASS" = "dbp-9902" ]; then
    CONTENT_OK=1
    break
  fi
  sleep 3
done
check_criterion "'app' container's /etc/combined has app.conf, api-key, AND db-pass, all with correct content" \
  [ "$CONTENT_OK" = "1" ]

print_score
