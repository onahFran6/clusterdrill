#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-05-secret-docker-registry-imagepullsecret${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'regcred' exists" \
  resource_exists secret regcred -n "$QUESTION_ID"

check_criterion "Secret 'regcred' is of type kubernetes.io/dockerconfigjson" \
  [ "$(kget secret regcred '{.type}' -n "$QUESTION_ID")" = "kubernetes.io/dockerconfigjson" ]

check_criterion "Secret 'regcred' encodes the registry.example.internal auth entry" \
  bash -c "kubectl get secret regcred -n '$QUESTION_ID' -o jsonpath='{.data.\.dockerconfigjson}' 2>/dev/null | base64 -d 2>/dev/null | grep -q 'registry.example.internal'"

check_criterion "Secret 'regcred' encodes username svc-deploy" \
  bash -c "kubectl get secret regcred -n '$QUESTION_ID' -o jsonpath='{.data.\.dockerconfigjson}' 2>/dev/null | base64 -d 2>/dev/null | grep -q 'svc-deploy'"

check_criterion "Pod 'private-app' lists regcred under imagePullSecrets" \
  [ "$(kget pod private-app '{.spec.imagePullSecrets[0].name}' -n "$QUESTION_ID")" = "regcred" ]

print_score
