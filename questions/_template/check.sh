#!/usr/bin/env bash
# Grades ONLY live cluster state - never a client-supplied "done" flag,
# never whether Hint/Solution was opened.
#
# No `set -e` here on purpose: check_criterion returns non-zero on a FAIL,
# which is a normal, expected result per criterion, not a script error. A
# `set -e` would abort the script on the first failed criterion and never
# reach print_score - exactly the false-0 bug verify-question.sh exists to
# catch, so don't reintroduce it here.
set -uo pipefail

QUESTION_ID="qNNN${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Example criteria - replace with this question's actual checks:
#
# check_criterion "ConfigMap 'example' exists" \
#   resource_exists configmap example -n "$QUESTION_ID"
#
# check_criterion "Pod 'app' mounts the ConfigMap" \
#   [ "$(kget pod app -n "$QUESTION_ID" '{.spec.volumes[0].configMap.name}')" = "example" ]

print_score
