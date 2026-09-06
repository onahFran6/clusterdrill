#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-43-configmap-binarydata-from-file${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Same deterministic byte sequence setup.sh wrote to ~/assets/logo.bin -
# regenerated here rather than hardcoding a base64/hash value, so there is
# exactly one place (this literal) that has to agree with setup.sh's.
EXPECTED_B64="$(printf '\xff\xfe\x01\x02\x03\x04\x05\x06' | base64 | tr -d '\n')"

check_criterion "ConfigMap 'app-assets' has key logo.bin under binaryData (not data)" \
  bash -c '
    bd="$(kubectl get configmap app-assets -n "'"$QUESTION_ID"'" -o jsonpath="{.binaryData.logo\.bin}" 2>/dev/null)"
    [ -n "$bd" ] || exit 1
    d="$(kubectl get configmap app-assets -n "'"$QUESTION_ID"'" -o jsonpath="{.data.logo\.bin}" 2>/dev/null)"
    [ -z "$d" ]
  '

check_criterion "ConfigMap 'app-assets' binaryData.logo.bin matches the original file bytes" \
  bash -c '
    bd="$(kubectl get configmap app-assets -n "'"$QUESTION_ID"'" -o jsonpath="{.binaryData.logo\.bin}" 2>/dev/null)"
    [ "$bd" = "'"$EXPECTED_B64"'" ]
  '

check_criterion "Pod 'asset-server' mounts app-assets as a volume at /etc/assets" \
  [ "$(kget pod asset-server '{.spec.volumes[?(@.configMap.name=="app-assets")].configMap.name}' -n "$QUESTION_ID")" = "app-assets" ]

check_criterion "Mounted /etc/assets/logo.bin has the exact original byte content" \
  bash -c '
    actual_b64="$(kubectl exec -n "'"$QUESTION_ID"'" asset-server -- cat /etc/assets/logo.bin 2>/dev/null | base64 | tr -d "\n")"
    [ "$actual_b64" = "'"$EXPECTED_B64"'" ]
  '

print_score
