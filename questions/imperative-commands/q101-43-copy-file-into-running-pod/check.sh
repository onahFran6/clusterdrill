#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-43-copy-file-into-running-pod${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "File /data/manifest.txt exists inside pod 'archive-box' with the exact copied content" \
  bash -c "
    VAL=\$(kubectl exec -n '$QUESTION_ID' archive-box -c archive-box -- cat /data/manifest.txt 2>/dev/null)
    EXPECTED=\$(printf 'build=482\nchannel=stable\n')
    [ \"\$VAL\" = \"\$EXPECTED\" ]
  "

print_score
