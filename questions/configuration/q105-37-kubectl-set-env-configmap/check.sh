#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-37-kubectl-set-env-configmap${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# `kubectl set env --from=configmap/X` expands each key into its own `env`
# entry with `valueFrom.configMapKeyRef` (not a single `envFrom` block), so
# this checks for either representation - whichever mechanism actually put
# DARK_MODE/BETA_UI on the container, they must be sourced from the
# ConfigMap, not hardcoded.
check_criterion "Deployment 'web-frontend' sources DARK_MODE and BETA_UI from ConfigMap 'feature-flags' (envFrom or per-key configMapKeyRef) AND has 1/1 ready replicas" \
  bash -c '
    envfrom_ref="$(kubectl get deployment web-frontend -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].envFrom[?(@.configMapRef.name==\"feature-flags\")].configMapRef.name}" 2>/dev/null)"
    dark_ref="$(kubectl get deployment web-frontend -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name==\"DARK_MODE\")].valueFrom.configMapKeyRef.name}" 2>/dev/null)"
    beta_ref="$(kubectl get deployment web-frontend -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name==\"BETA_UI\")].valueFrom.configMapKeyRef.name}" 2>/dev/null)"
    if [ "$envfrom_ref" = "feature-flags" ]; then
      :
    elif [ "$dark_ref" = "feature-flags" ] && [ "$beta_ref" = "feature-flags" ]; then
      :
    else
      exit 1
    fi
    ready="$(kubectl get deployment web-frontend -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$ready" = "1" ]
  '

check_criterion "Running pod for web-frontend reports DARK_MODE=true and BETA_UI=false, and ConfigMap 'feature-flags' is unchanged" \
  bash -c '
    pod="$(kubectl get pods -n "'"$QUESTION_ID"'" -l app=web-frontend -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)"
    [ -n "$pod" ] || exit 1
    dark="$(kubectl exec -n "'"$QUESTION_ID"'" "$pod" -- sh -c "echo \$DARK_MODE" 2>/dev/null)"
    [ "$dark" = "true" ] || exit 1
    beta="$(kubectl exec -n "'"$QUESTION_ID"'" "$pod" -- sh -c "echo \$BETA_UI" 2>/dev/null)"
    [ "$beta" = "false" ] || exit 1
    d="$(kubectl get configmap feature-flags -n "'"$QUESTION_ID"'" -o jsonpath="{.data.DARK_MODE}" 2>/dev/null)"
    [ "$d" = "true" ] || exit 1
    b="$(kubectl get configmap feature-flags -n "'"$QUESTION_ID"'" -o jsonpath="{.data.BETA_UI}" 2>/dev/null)"
    [ "$b" = "false" ]
  '

print_score
