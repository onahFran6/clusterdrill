#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-49-crd-json-patch-array-append${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Playlist 'mix1' spec.tracks is exactly [song-a, song-b, song-c] in order" \
  [ "$(kget playlist mix1 '{.spec.tracks}' -n "$QUESTION_ID")" = '["song-a","song-b","song-c"]' ]

print_score
