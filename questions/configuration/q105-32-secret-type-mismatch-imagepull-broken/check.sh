#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-32-secret-type-mismatch-imagepull-broken${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled on purpose: right after setup.sh, a Secret named 'registry-cred'
# already exists and the Deployment's pod template already references it
# under imagePullSecrets - both trivially true before the candidate does
# anything. Nothing scores here until registry-cred is ALSO of the correct
# type/key shape (kubernetes.io/dockerconfigjson with a valid
# .dockerconfigjson JSON payload containing an auths entry for the given
# registry + username), which only happens once the candidate deletes and
# recreates it correctly.
# Walked with plain jq/grep (no python3 dependency): validate the type,
# that .dockerconfigjson decodes as syntactically valid JSON with jq, that
# its auths object has a key for the given registry server, and that the
# embedded entry mentions the given username - then confirm the Deployment
# still references registry-cred under imagePullSecrets.
check_criterion "Secret 'registry-cred' is type kubernetes.io/dockerconfigjson with a valid .dockerconfigjson payload for registry.example.internal/svc-deploy, and Deployment 'private-app' still references it under imagePullSecrets" \
  bash -c "
    set -e
    [ \"\$(kubectl get secret registry-cred -n '$QUESTION_ID' -o jsonpath='{.type}' 2>/dev/null)\" = 'kubernetes.io/dockerconfigjson' ]
    payload=\$(kubectl get secret registry-cred -n '$QUESTION_ID' -o jsonpath='{.data.\.dockerconfigjson}' 2>/dev/null | base64 -d 2>/dev/null)
    [ -n \"\$payload\" ]
    echo \"\$payload\" | jq -e '.auths[\"registry.example.internal\"]' >/dev/null 2>&1
    echo \"\$payload\" | jq -e '.auths[\"registry.example.internal\"].username == \"svc-deploy\"' >/dev/null 2>&1
    [ \"\$(kubectl get deployment private-app -n '$QUESTION_ID' -o jsonpath='{.spec.template.spec.imagePullSecrets[0].name}' 2>/dev/null)\" = 'registry-cred' ]
  "

print_score
