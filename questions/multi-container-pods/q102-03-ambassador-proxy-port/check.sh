#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-03-ambassador-proxy-port${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'app-with-ambassador' exists" \
  resource_exists pod app-with-ambassador -n "$QUESTION_ID"

check_criterion "Pod has exactly 2 containers" \
  [ "$(kget pod app-with-ambassador '{.spec.containers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "2" ]

APP_IMAGE="$(kget pod app-with-ambassador '{.spec.containers[?(@.name=="app")].image}' -n "$QUESTION_ID")"
check_criterion "'app' container uses busybox image" \
  bash -c "echo '$APP_IMAGE' | grep -q busybox"

AMBASSADOR_IMAGE="$(kget pod app-with-ambassador '{.spec.containers[?(@.name=="ambassador")].image}' -n "$QUESTION_ID")"
check_criterion "'ambassador' container uses alpine image" \
  bash -c "echo '$AMBASSADOR_IMAGE' | grep -q alpine"

APP_CMD="$(kget pod app-with-ambassador '{.spec.containers[?(@.name=="app")]}' -n "$QUESTION_ID")"
check_criterion "'app' container talks to localhost:6380" \
  bash -c "echo '$APP_CMD' | grep -q 'localhost:6380'"

AMBASSADOR_CMD="$(kget pod app-with-ambassador '{.spec.containers[?(@.name=="ambassador")]}' -n "$QUESTION_ID")"
check_criterion "'ambassador' container listens on 6380" \
  bash -c "echo '$AMBASSADOR_CMD' | grep -q '6380'"

check_criterion "'ambassador' container forwards to port 6379" \
  bash -c "echo '$AMBASSADOR_CMD' | grep -q '6379'"

check_criterion "'ambassador' container uses socat to proxy" \
  bash -c "echo '$AMBASSADOR_CMD' | grep -q 'socat'"

print_score
