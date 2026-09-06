#!/usr/bin/env bash
# Shared grading helpers, sourced by every question's check.sh/setup.sh
#. Do not `set -e` in this file - check.sh scripts
# need one failing criterion to not abort the rest of the checklist.

CLUSTERDRILL_LABEL_KEY="clusterdrill-question"

# apply_default_resource_limits <namespace>
# A mandatory ResourceQuota + LimitRange
# pair, applied by every question's setup.sh right after it creates its own
# namespace - a security control, not tuning: once multiple accounts share
# one small worker node, one account must not be able to starve or attack
# every other account's pods by running something unbounded (a crypto-
# miner, a fork bomb, an accidental infinite-scale Deployment) in their own
# namespace.
#
# ResourceQuota and LimitRange are a *pair*, not independently optional:
# once a namespace's ResourceQuota constrains requests.cpu/requests.memory/
# limits.cpu/limits.memory, Kubernetes requires every pod in that namespace
# to specify all four explicitly, or admission rejects the pod outright
# (see https://kubernetes.io/docs/concepts/policy/resource-quotas/#requests-vs-limits).
# Almost none of this bank's ~178 questions specify pod resources at all
# (checked directly: 12 do) - without the LimitRange auto-filling sane
# defaults for the rest, adding the ResourceQuota alone would break nearly
# every question's setup.sh the moment it tries to create a plain pod.
#
# Sizing rationale (checked against every question that *does* specify
# resources, including the one outlier - q104-19's HPA demo, whose
# reference answer sets minReplicas=4 at 100m cpu request each = 400m):
#   - requests.cpu=600m / requests.memory=320Mi: what actually gates how
#     many concurrent users' pods the scheduler can place on a 2 vCPU/2GB
#     node at once (~3 full-quota namespaces' worth) - this is the real
#     abuse-prevention ceiling.
#   - limits.cpu=1200m / limits.memory=640Mi: looser ceiling for bursty
#     workloads (CPU limits are CFS-throttled, not OOM-killed, when
#     oversubscribed at the node level, so some looseness here is safe).
#   - pods=12: high enough that q104-19's HPA maxReplicas=12 isn't
#     artificially blocked by pod *count* specifically (requests.cpu
#     becomes the practical scaling ceiling before pod count does, which
#     is a realistic teaching moment, not a broken one - kubectl autoscale
#     itself, the thing check.sh actually grades, is unaffected either way
#     since creating an HPA object isn't itself constrained by a compute
#     ResourceQuota).
#
# NOT applied to every namespace: q105-12-limitrange-defaults and
# q105-21-limitrange-min-max-bounds are themselves CKAD questions about
# authoring a namespace's *own* LimitRange from a clean namespace - a
# competing pre-existing LimitRange here would directly invalidate what
# those two specifically grade (their check.sh asserts a pod picked up
# *their* candidate-authored LimitRange's exact default/min/max values).
# Those two questions' own setup.sh simply never calls this function.
apply_default_resource_limits() {
  local namespace="$1"
  if [[ -z "$namespace" ]]; then
    echo "apply_default_resource_limits: namespace is required" >&2
    return 1
  fi
  kubectl apply -n "$namespace" -f - <<'EOF' >/dev/null
apiVersion: v1
kind: ResourceQuota
metadata:
  name: clusterdrill-default-quota
spec:
  hard:
    pods: "12"
    requests.cpu: "600m"
    requests.memory: "320Mi"
    limits.cpu: "1200m"
    limits.memory: "640Mi"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: clusterdrill-default-limits
spec:
  limits:
    - type: Container
      defaultRequest:
        cpu: "50m"
        memory: "64Mi"
      default:
        cpu: "200m"
        memory: "128Mi"
EOF
}

# question_workdir <question_id>
# Prints the path to that question's terminal working directory, creating
# it if missing - mirrors app.py's WORK_DIR_ROOT/question_workdir() exactly
# (same $HOME/practice-work/<question_id> layout), so a file a setup.sh
# seeds here shows up right where the candidate's terminal actually starts.
# Use this instead of a hand-rolled /tmp/<qid>-<name> path for any question
# that needs a local file (e.g. a source file for --from-file, or a broken
# manifest to fix) - no other question ever peeks at another's tmp files
# used to make that safe by convention alone, but a real per-question folder
# does it properly.
question_workdir() {
  local question_id="$1"
  local dir="$HOME/practice-work/$question_id"
  mkdir -p "$dir"
  echo "$dir"
}

# Counters reset every time this file is sourced (each check.sh run is its
# own process, so these always start fresh).
_CLUSTERDRILL_CHECKS_TOTAL=0
_CLUSTERDRILL_CHECKS_PASSED=0

# resource_exists <kind> <name> [kubectl-args...]
#   resource_exists configmap example -n q001
resource_exists() {
  local kind="$1" name="$2"
  shift 2
  kubectl get "$kind" "$name" "$@" >/dev/null 2>&1
}

# kget <kind> <name> <jsonpath> [kubectl-args...]
#   kget pod app '{.spec.containers[0].image}' -n q001
# Prints the jsonpath result to stdout; prints nothing (empty string) if the
# resource or path doesn't exist - callers compare against expected values.
kget() {
  local kind="$1" name="$2" jsonpath="$3"
  shift 3
  kubectl get "$kind" "$name" -o "jsonpath=$jsonpath" "$@" 2>/dev/null
}

# check_criterion "<description>" <command...>
# Runs <command...>, records PASS/FAIL, and prints a stable, line-oriented
# format the web UI parses for its live per-criterion checklist:
#   CRITERION: <description> = PASS
#   CRITERION: <description> = FAIL
# Keep this format stable - it's a parsing contract, not just log output.
# Returns the underlying command's exit status (0 on pass) so check.sh can
# also use it in a conditional if needed.
check_criterion() {
  local description="$1"
  shift
  _CLUSTERDRILL_CHECKS_TOTAL=$((_CLUSTERDRILL_CHECKS_TOTAL + 1))
  if "$@" >/dev/null 2>&1; then
    _CLUSTERDRILL_CHECKS_PASSED=$((_CLUSTERDRILL_CHECKS_PASSED + 1))
    echo "CRITERION: $description = PASS"
    return 0
  else
    echo "CRITERION: $description = FAIL"
    return 1
  fi
}

# print_score
# Must be the last line every check.sh emits. Stable format:
#   SCORE: <passed>/<total>
# verify-question.sh and the web UI both parse this line.
print_score() {
  echo "SCORE: ${_CLUSTERDRILL_CHECKS_PASSED}/${_CLUSTERDRILL_CHECKS_TOTAL}"
}

# full_reset <question_id>
# The only reset path - no soft-reset helper exists on purpose. Deletes the question's namespace AND anything
# cluster-scoped labeled for it, and waits for both to finish before
# returning, so a subsequent setup.sh never races a Terminating namespace.
full_reset() {
  local question_id="$1"
  if [[ -z "$question_id" ]]; then
    echo "full_reset: question id is required" >&2
    return 1
  fi

  # Namespace names and label values must be lowercase RFC 1123, but a
  # handful of question folders (and thus verify-question.sh's basename-
  # derived question_id) contain camelCase (e.g. q107-21-preStop-...) - their
  # own setup.sh already lowercases QUESTION_ID before using it as a
  # namespace/label value, so this must match or the delete below silently
  # no-ops (--ignore-not-found masks it) and leaks the real namespace
  # forever. Lowercasing here, not renaming every mixed-case folder, keeps
  # this the one place that has to know about the mismatch.
  local question_id_lc="${question_id,,}"

  if ! kubectl delete namespace "$question_id_lc" --ignore-not-found --wait=true >/dev/null 2>&1; then
    echo "full_reset: failed to delete namespace $question_id_lc" >&2
    return 1
  fi

  if ! kubectl delete clusterrole,clusterrolebinding,pv,storageclass,crd \
    -l "${CLUSTERDRILL_LABEL_KEY}=${question_id_lc}" \
    --ignore-not-found --wait=true >/dev/null 2>&1; then
    echo "full_reset: failed to delete cluster-scoped resources for $question_id_lc" >&2
    return 1
  fi

  echo "full_reset: $question_id cleaned"
}

# batch_cleanup <question_id> [<question_id> ...]
# Bulk teardown for a whole session/batch that just ended (its questions
# aren't necessarily coming back) - one batched kubectl call per resource
# type instead of looping full_reset per question. Unlike full_reset, does
# NOT wait for termination (--wait=false): the caller (a session ending)
# doesn't need these gone before it returns, just heading toward gone, so
# tearing down a full 15-question session doesn't block on up to 15
# sequential namespace terminations. Any question re-provisions on its own
# next view regardless (setup.sh is idempotent, auto-run on first view).
batch_cleanup() {
  if [[ "$#" -eq 0 ]]; then
    echo "batch_cleanup: at least one question id is required" >&2
    return 1
  fi

  kubectl delete namespace "$@" --ignore-not-found --wait=false >/dev/null 2>&1

  local joined
  joined="$(IFS=,; echo "$*")"
  kubectl delete clusterrole,clusterrolebinding,pv,storageclass,crd \
    -l "${CLUSTERDRILL_LABEL_KEY} in (${joined})" \
    --ignore-not-found --wait=false >/dev/null 2>&1

  echo "batch_cleanup: $# question(s) cleaned"
}

# grant_user_namespace_access <namespace> <user_id>
# The actual answer to "a logged-in user's
# terminal must not be able to read/modify another user's namespace" -
# earlier work isolated *where* each user's resources live
# (separate namespaces, separate quotas), but every terminal session still
# shared the same cluster-admin kubeconfig, so alice's shell could still run
# `kubectl get pods -n <bobs-namespace>` directly. This grants a namespace-
# scoped Role+RoleBinding to that one user's ServiceAccount
# (system:serviceaccount:clusterdrill-system:<user_id>, provisioned by
# web/rbac.py) - full access *within this one namespace only*, nothing
# cluster-wide. ttyd_manager.py points that user's terminal at a kubeconfig
# authenticating as this ServiceAccount instead of the app's own admin
# kubeconfig (which check.sh/setup.sh themselves still use, unaffected -
# this only restricts the interactive terminal).
#
# A no-op when user_id is empty (password gate off / no accounts) - matches
# every other per-user mechanism in this file (apply_default_resource_limits,
# CLUSTERDRILL_NAMESPACE_SUFFIX): zero behavior change for local dev/SSH-tunnel use,
# where the terminal already only has the one trusted operator's own
# kubeconfig.
#
# Deliberately wildcard (apiGroups/resources: "*") rather than an
# enumerated resource list: the isolation boundary here is the *namespace*
# (this Role only exists in this one namespace), not resource-type
# filtering - enumerating every kind a CKAD question might ever touch and
# keeping that list in sync as questions are added would be a maintenance
# trap for no real security benefit, since anything this Role reaches is
# already confined to this one namespace either way.
grant_user_namespace_access() {
  local namespace="$1" user_id="$2"
  if [[ -z "$namespace" ]]; then
    echo "grant_user_namespace_access: namespace is required" >&2
    return 1
  fi
  if [[ -z "$user_id" ]]; then
    return 0
  fi
  kubectl apply -n "$namespace" -f - <<EOF >/dev/null
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: clusterdrill-system-access
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: clusterdrill-system-access-binding
subjects:
  - kind: ServiceAccount
    name: ${user_id}
    namespace: clusterdrill-system
roleRef:
  kind: Role
  name: clusterdrill-system-access
  apiGroup: rbac.authorization.k8s.io
EOF
}
