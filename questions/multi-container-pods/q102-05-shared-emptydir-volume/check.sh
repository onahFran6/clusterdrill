#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-05-shared-emptydir-volume${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'shared-vol-demo' has exactly 2 containers" \
  [ "$(kget pod shared-vol-demo '{.spec.containers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "2" ]

check_criterion "'producer' container mounts volume 'shared' at /producer-data" \
  [ "$(kget pod shared-vol-demo '{.spec.containers[?(@.name=="producer")].volumeMounts[?(@.name=="shared")].mountPath}' -n "$QUESTION_ID")" = "/producer-data" ]

check_criterion "'consumer' container mounts volume 'shared' at /consumer-data" \
  [ "$(kget pod shared-vol-demo '{.spec.containers[?(@.name=="consumer")].volumeMounts[?(@.name=="shared")].mountPath}' -n "$QUESTION_ID")" = "/consumer-data" ]

check_criterion "Pod defines an emptyDir volume named 'shared'" \
  [ "$(kget pod shared-vol-demo '{.spec.volumes[?(@.name=="shared")].emptyDir}' -n "$QUESTION_ID")" = "{}" ]

PRODUCER_IMAGE="$(kget pod shared-vol-demo '{.spec.containers[?(@.name=="producer")].image}' -n "$QUESTION_ID")"
check_criterion "'producer' container uses busybox image" \
  bash -c "echo '$PRODUCER_IMAGE' | grep -q busybox"

CONSUMER_IMAGE="$(kget pod shared-vol-demo '{.spec.containers[?(@.name=="consumer")].image}' -n "$QUESTION_ID")"
check_criterion "'consumer' container uses busybox image" \
  bash -c "echo '$CONSUMER_IMAGE' | grep -q busybox"

print_score
