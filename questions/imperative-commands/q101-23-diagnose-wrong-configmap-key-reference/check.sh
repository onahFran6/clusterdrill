#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-23-diagnose-wrong-configmap-key-reference${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh already leaves the pod in CreateContainerConfigError (not Ready),
# so bundle "phase Running" together with "container actually Ready" in one
# criterion - neither half is true until the candidate fixes the key
# reference, so this can't score before the real fix lands.
check_criterion "Pod 'settings-reader' is Running and container Ready" \
  bash -c "
    [ \"\$(kubectl get pod settings-reader -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ] &&
    [ \"\$(kubectl get pod settings-reader -n '$QUESTION_ID' -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)\" = 'true' ]
  "

# The container name/image must not have been swapped out for some other
# workaround, bundled with the Ready half so this can't score in the
# unsolved state (name/image alone are already correct right after setup.sh).
check_criterion "Pod keeps container name 'settings-reader' on image nginx:1.25-alpine, and is Ready" \
  bash -c "
    [ \"\$(kubectl get pod settings-reader -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].name}' 2>/dev/null)\" = 'settings-reader' ] &&
    [ \"\$(kubectl get pod settings-reader -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)\" = 'nginx:1.25-alpine' ] &&
    [ \"\$(kubectl get pod settings-reader -n '$QUESTION_ID' -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)\" = 'true' ]
  "

# envFrom must still be wired to the app-settings ConfigMap (untouched by the
# fix) - bundled with the Ready check so this can't score before the pod
# actually starts (envFrom alone is already correct right after setup.sh).
check_criterion "Container loads all keys from ConfigMap 'app-settings' via envFrom, and pod is Ready" \
  bash -c "
    [ \"\$(kubectl get pod settings-reader -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].envFrom[0].configMapRef.name}' 2>/dev/null)\" = 'app-settings' ] &&
    [ \"\$(kubectl get pod settings-reader -n '$QUESTION_ID' -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)\" = 'true' ]
  "

# The extra named env var must still be a configMapKeyRef (not hardcoded),
# and must now point at the real key MAX_CONNECTIONS instead of the typo'd
# MAX_CONN - this is the actual fix, and is false in the unsolved state.
check_criterion "Extra env var's valueFrom.configMapKeyRef now points at key MAX_CONNECTIONS" \
  bash -c "
    NAME=\$(kubectl get pod settings-reader -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].env[0].name}' 2>/dev/null)
    REF_NAME=\$(kubectl get pod settings-reader -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].env[0].valueFrom.configMapKeyRef.name}' 2>/dev/null)
    REF_KEY=\$(kubectl get pod settings-reader -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].env[0].valueFrom.configMapKeyRef.key}' 2>/dev/null)
    LITERAL=\$(kubectl get pod settings-reader -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].env[0].value}' 2>/dev/null)
    [ -n \"\$NAME\" ] && [ \"\$REF_NAME\" = 'app-settings' ] && [ \"\$REF_KEY\" = 'MAX_CONNECTIONS' ] && [ -z \"\$LITERAL\" ]
  "

# Final proof: the running container's actual environment resolves the fixed
# variable to the real ConfigMap value, not just the spec looking right.
check_criterion "Container's env var for the fixed key resolves to 100 inside the running container" \
  bash -c "
    ENV_NAME=\$(kubectl get pod settings-reader -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].env[0].name}' 2>/dev/null)
    [ -n \"\$ENV_NAME\" ] || exit 1
    VAL=\$(kubectl exec -n '$QUESTION_ID' settings-reader -- sh -c \"eval echo \\\\\\$\$ENV_NAME\" 2>/dev/null)
    [ \"\$VAL\" = '100' ]
  "

check_criterion "Container also still sees MAX_CONNECTIONS=100 via envFrom" \
  bash -c "kubectl exec -n '$QUESTION_ID' settings-reader -- sh -c 'echo \$MAX_CONNECTIONS' 2>/dev/null | grep -qx '100'"

print_score
