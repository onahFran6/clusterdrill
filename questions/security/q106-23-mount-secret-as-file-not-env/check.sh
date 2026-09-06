#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-23-mount-secret-as-file-not-env${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl wait --for=condition=Ready pod/cert-reader -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1

check_criterion "Pod 'cert-reader' exists and is Running" \
  bash -c "[ \"\$(kubectl get pod cert-reader -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ]"

check_criterion "Pod 'cert-reader' uses image busybox:1.36" \
  bash -c "[ \"\$(kubectl get pod cert-reader -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)\" = 'busybox:1.36' ]"

check_criterion "Volume mount at /etc/tls backed by Secret 'tls-cert' is read-only" \
  bash -c "
    mount_name=\$(kubectl get pod cert-reader -n '$QUESTION_ID' \
      -o jsonpath='{.spec.containers[0].volumeMounts[?(@.mountPath==\"/etc/tls\")].name}' 2>/dev/null)
    mount_ro=\$(kubectl get pod cert-reader -n '$QUESTION_ID' \
      -o jsonpath='{.spec.containers[0].volumeMounts[?(@.mountPath==\"/etc/tls\")].readOnly}' 2>/dev/null)
    vol_secret=\$(kubectl get pod cert-reader -n '$QUESTION_ID' \
      -o jsonpath=\"{.spec.volumes[?(@.name==\\\"\$mount_name\\\")].secret.secretName}\" 2>/dev/null)
    [ -n \"\$mount_name\" ] && [ \"\$mount_ro\" = 'true' ] && [ \"\$vol_secret\" = 'tls-cert' ]
  "

check_criterion "cert-reader can list both tls.crt and tls.key under /etc/tls" \
  bash -c "
    out=\$(kubectl exec cert-reader -n '$QUESTION_ID' -- ls /etc/tls 2>/dev/null)
    echo \"\$out\" | grep -q '^tls.crt\$' && echo \"\$out\" | grep -q '^tls.key\$'
  "

print_score
