#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q101-24-fix-secret-mount-wrong-key-path${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh already creates a pod named 'cert-server' (it's just broken), so
# "pod exists" alone would trivially pass pre-solve. Bundled with
# Running/Ready here so nothing scores until the candidate actually fixes
# the volume and the pod comes up healthy.
# Note: bash -c below spawns a fresh shell that doesn't inherit sourced
# functions like kget, so kubectl is invoked directly with -o jsonpath.
check_criterion "Pod 'cert-server' exists, is Running and Ready" \
  bash -c "
    [ \"\$(kubectl get pod cert-server -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ] &&
    [ \"\$(kubectl get pod cert-server -n '$QUESTION_ID' -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)\" = 'true' ]
  "

# setup.sh already points the volume at Secret 'tls-creds' / mountPath
# /etc/certs (that part was never wrong) - bundled here with the actual
# fix (items[].key must become tls.crt, not the original bogus cert.pem)
# so this criterion isn't trivially true pre-solve.
check_criterion "Volume mounts Secret 'tls-creds' at /etc/certs, exposing exactly one file (cert.pem) sourced from key 'tls.crt'" \
  bash -c "
    [ \"\$(kubectl get pod cert-server -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[0].secret.secretName}' 2>/dev/null)\" = 'tls-creds' ] &&
    [ \"\$(kubectl get pod cert-server -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].volumeMounts[0].mountPath}' 2>/dev/null)\" = '/etc/certs' ] &&
    [ \"\$(kubectl get pod cert-server -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[0].secret.items[*].key}' 2>/dev/null)\" = 'tls.crt' ] &&
    [ \"\$(kubectl get pod cert-server -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[0].secret.items[*].path}' 2>/dev/null)\" = 'cert.pem' ]
  "

check_criterion "'cat /etc/certs/cert.pem' inside the pod matches Secret's tls.crt value" \
  bash -c "
    expected=\"\$(kubectl get secret tls-creds -n '$QUESTION_ID' -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d)\"
    actual=\"\$(kubectl exec cert-server -n '$QUESTION_ID' -- cat /etc/certs/cert.pem 2>/dev/null)\"
    [ -n \"\$actual\" ] && [ \"\$actual\" = \"\$expected\" ]
  "

print_score
