#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-07-clusterrole-node-viewer${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ClusterRole 'q106-07-node-viewer' exists" \
  resource_exists clusterrole q106-07-node-viewer

check_criterion "ClusterRole 'q106-07-node-viewer' targets resource 'nodes'" \
  [ "$(kget clusterrole q106-07-node-viewer '{.rules[0].resources[0]}')" = "nodes" ]

CR_VERBS="$(kget clusterrole q106-07-node-viewer '{.rules[0].verbs}')"

check_criterion "ClusterRole 'q106-07-node-viewer' grants verb 'get'" \
  bash -c "[[ '$CR_VERBS' == *get* ]]"

check_criterion "ClusterRole 'q106-07-node-viewer' grants verb 'list'" \
  bash -c "[[ '$CR_VERBS' == *list* ]]"

check_criterion "ClusterRole 'q106-07-node-viewer' grants verb 'watch'" \
  bash -c "[[ '$CR_VERBS' == *watch* ]]"

check_criterion "ClusterRole 'q106-07-node-viewer' carries the clusterdrill-question label" \
  [ "$(kget clusterrole q106-07-node-viewer '{.metadata.labels.clusterdrill-question}')" = "$QUESTION_ID" ]

print_score
