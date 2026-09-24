#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-56-helm-list-all-namespaces-failed-filter${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
ALL_FILE="$WORK_DIR/all-releases.json"
FAILED_FILE="$WORK_DIR/failed-releases.json"

check_criterion "all-releases.json exists and lists all three releases" \
  bash -c '[ -f "$1" ] && grep -q svc-one "$1" && grep -q svc-two "$1" && grep -q svc-three "$1"' _ "$ALL_FILE"

check_criterion "failed-releases.json exists and lists svc-three" \
  bash -c '[ -f "$1" ] && grep -q svc-three "$1"' _ "$FAILED_FILE"

check_criterion "failed-releases.json excludes the healthy releases (svc-one, svc-two)" \
  bash -c '[ -f "$1" ] && ! grep -q svc-one "$1" && ! grep -q svc-two "$1"' _ "$FAILED_FILE"

print_score
