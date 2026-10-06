#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-19-immutable-config-persistent-output${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap render-v2 exists, immutable, greeting=bonjour" \
  bash -c '
    immut="$(kubectl get cm render-v2 -n "'"$QUESTION_ID"'" -o jsonpath="{.immutable}" 2>/dev/null)"
    greet="$(kubectl get cm render-v2 -n "'"$QUESTION_ID"'" -o jsonpath="{.data.greeting}" 2>/dev/null)"
    [ "$immut" = "true" ] && [ "$greet" = "bonjour" ]
  '

# Bundled on purpose: "render-v1 untouched" is already true the instant
# setup.sh finishes, before any candidate action - only combined with the
# Deployment actually repointed at render-v2 does this prove real work.
check_criterion "render-v1 left completely untouched AND render's volume now references render-v2" \
  bash -c '
    v1_greet="$(kubectl get cm render-v1 -n "'"$QUESTION_ID"'" -o jsonpath="{.data.greeting}" 2>/dev/null)"
    v1_immut="$(kubectl get cm render-v1 -n "'"$QUESTION_ID"'" -o jsonpath="{.immutable}" 2>/dev/null)"
    vol_cm="$(kubectl get deployment render -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.volumes[?(@.name==\"tpl\")].configMap.name}" 2>/dev/null)"
    [ "$v1_greet" = "hello" ] && [ "$v1_immut" = "true" ] && [ "$vol_cm" = "render-v2" ]
  '

# Bundled on purpose: "Deployment Running" is already true in the unsolved
# seed - only combined with the actual two-line history (proving a real
# second rollout happened against the new ConfigMap) does this mean
# anything.
check_criterion "Deployment render is Running AND /out/history holds the original hello line plus a new bonjour line" \
  bash -c '
    for i in $(seq 1 10); do
      ready="$(kubectl get deployment render -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
      if [ "$ready" = "1" ]; then
        out="$(kubectl exec deploy/render -n "'"$QUESTION_ID"'" -- tail -n 2 /out/history 2>/dev/null)"
        if echo "$out" | grep -q "^hello world" && echo "$out" | grep -q "^bonjour world"; then
          exit 0
        fi
      fi
      sleep 3
    done
    exit 1
  '

print_score
