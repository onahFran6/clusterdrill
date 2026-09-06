#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
#
# Note on ordering: "schedule is still '0 9 * * *'" is true the instant
# setup.sh finishes, before the candidate does anything - graded alone it
# would violate the "unsolved state scores 0" gate. It's folded into the
# same criterion as "timeZone is America/New_York", which is only true
# once the candidate has actually set the field, so nothing scores here
# until the real fix lands.
set -uo pipefail

QUESTION_ID="q103-19-cronjob-timezone-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

_schedule="$(kget cronjob morning-standup-reminder '{.spec.schedule}' -n "$QUESTION_ID")"
_timezone="$(kget cronjob morning-standup-reminder '{.spec.timeZone}' -n "$QUESTION_ID")"

check_criterion "CronJob 'morning-standup-reminder' keeps schedule '0 9 * * *' and has spec.timeZone 'America/New_York'" \
  bash -c '[ "$1" = "0 9 * * *" ] && [ "$2" = "America/New_York" ]' _ \
  "$_schedule" "$_timezone"

print_score
