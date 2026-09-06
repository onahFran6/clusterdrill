#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-16-adapter-metrics-exporter${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'metrics-app' has exactly 2 containers" \
  [ "$(kget pod metrics-app '{.spec.containers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "2" ]

check_criterion "Container 'metrics-adapter' present with busybox image" \
  [ "$(kget pod metrics-app '{.spec.containers[?(@.name=="metrics-adapter")].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "'metrics-adapter' mounts metrics-vol at /metrics" \
  [ "$(kget pod metrics-app '{.spec.containers[?(@.name=="metrics-adapter")].volumeMounts[?(@.name=="metrics-vol")].mountPath}' -n "$QUESTION_ID")" = "/metrics" ]

ADAPTER_CMD="$(kget pod metrics-app '{.spec.containers[?(@.name=="metrics-adapter")].command}' -n "$QUESTION_ID")"
check_criterion "'metrics-adapter' command references raw.txt" \
  bash -c "echo '$ADAPTER_CMD' | grep -q raw.txt"

check_criterion "'metrics-adapter' command references prometheus.txt" \
  bash -c "echo '$ADAPTER_CMD' | grep -q prometheus.txt"

print_score
