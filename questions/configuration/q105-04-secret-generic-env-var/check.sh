#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-04-secret-generic-env-var${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'billing-secret' exists" \
  resource_exists secret billing-secret -n "$QUESTION_ID"

check_criterion "Secret 'billing-secret' has key DB_PASSWORD=s3cr3t-pass" \
  [ "$(kubectl get secret billing-secret -n "$QUESTION_ID" -o jsonpath='{.data.DB_PASSWORD}' 2>/dev/null | base64 -d 2>/dev/null)" = "s3cr3t-pass" ]

check_criterion "Pod 'billing-app' has env var DATABASE_PASSWORD sourced from a secretKeyRef" \
  [ "$(kget pod billing-app '{.spec.containers[0].env[?(@.name=="DATABASE_PASSWORD")].valueFrom.secretKeyRef.name}' -n "$QUESTION_ID")" = "billing-secret" ]

check_criterion "That secretKeyRef points at key DB_PASSWORD" \
  [ "$(kget pod billing-app '{.spec.containers[0].env[?(@.name=="DATABASE_PASSWORD")].valueFrom.secretKeyRef.key}' -n "$QUESTION_ID")" = "DB_PASSWORD" ]

check_criterion "Container actually sees DATABASE_PASSWORD=s3cr3t-pass" \
  [ "$(kubectl exec -n "$QUESTION_ID" billing-app -- sh -c 'echo $DATABASE_PASSWORD' 2>/dev/null)" = "s3cr3t-pass" ]

print_score
