#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q111-01-deployment-envfrom-and-secretkeyref${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'api' has 3/3 ready replicas" \
  [ "$(kget deployment api '{.status.readyReplicas}' -n "$QUESTION_ID")" = "3" ]

check_criterion "Container is named 'api' running image nginx:1.27" \
  bash -c '
    name="$(kubectl get deployment api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].name}" 2>/dev/null)"
    image="$(kubectl get deployment api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$name" = "api" ] && [ "$image" = "nginx:1.27" ]
  '

check_criterion "Pod template carries label tier=backend" \
  [ "$(kget deployment api '{.spec.template.metadata.labels.tier}' -n "$QUESTION_ID")" = "backend" ]

check_criterion "Container imports every api-config key via envFrom" \
  [ "$(kget deployment api '{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}' -n "$QUESTION_ID")" = "api-config" ]

check_criterion "Secret's DB_PASSWORD reaches the container only as DATABASE_PASSWORD" \
  bash -c '
    name="$(kubectl get deployment api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name==\"DATABASE_PASSWORD\")].valueFrom.secretKeyRef.name}" 2>/dev/null)"
    key="$(kubectl get deployment api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name==\"DATABASE_PASSWORD\")].valueFrom.secretKeyRef.key}" 2>/dev/null)"
    [ "$name" = "api-creds" ] && [ "$key" = "DB_PASSWORD" ]
  '

check_criterion "Env var APP_ENV=staging is set" \
  bash -c '
    value="$(kubectl get deployment api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name==\"APP_ENV\")].value}" 2>/dev/null)"
    [ "$value" = "staging" ]
  '

check_criterion "Container requests cpu=100m,memory=64Mi and limits memory=128Mi" \
  bash -c '
    rcpu="$(kubectl get deployment api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.requests.cpu}" 2>/dev/null)"
    rmem="$(kubectl get deployment api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.requests.memory}" 2>/dev/null)"
    lmem="$(kubectl get deployment api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.limits.memory}" 2>/dev/null)"
    [ "$rcpu" = "100m" ] && [ "$rmem" = "64Mi" ] && [ "$lmem" = "128Mi" ]
  '

print_score
