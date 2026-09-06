#!/usr/bin/env bash
# Gets a local minikube cluster ready for practice-bank content authoring and
# lib/verify-question.sh runs. This is the day-to-day authoring/dev target
# for question content - a dedicated disposable cluster elsewhere is also a
# supported target, but nothing in practice-bank/ should ever assume it's
# the one in use.
#
# No AWS assumptions here on purpose:
# this must work for a stranger with nothing but a laptop and minikube
# installed. It does NOT install minikube or kubectl - it fails with a clear
# message if either binary is missing.
#
# Idempotent: safe to run against an already-running cluster. It will not
# recreate or restart a healthy profile, or re-enable addons that are already
# enabled.
#
# Usage:
#   lib/bootstrap-minikube.sh
#   MINIKUBE_PROFILE=clusterdrill lib/bootstrap-minikube.sh
#   MINIKUBE_CPUS=4 MINIKUBE_MEMORY=8g lib/bootstrap-minikube.sh
#   MINIKUBE_DRIVER=virtualbox lib/bootstrap-minikube.sh
#   MINIKUBE_K8S_VERSION=v1.33.1 lib/bootstrap-minikube.sh
#
# Overridable environment variables (all optional):
#   MINIKUBE_PROFILE     minikube profile name       (default: clusterdrill)
#   MINIKUBE_CPUS        CPUs given to the VM/container (default: 2)
#   MINIKUBE_MEMORY      memory given to the VM/container (default: 4g)
#   MINIKUBE_DRIVER      minikube driver, e.g. docker, hyperkit, virtualbox
#                        (default: let minikube auto-detect - unset/empty)
#   MINIKUBE_K8S_VERSION Kubernetes version passed to --kubernetes-version
#                        (default: "stable", i.e. minikube's own pinned
#                        stable release - see the version note below)
#   MINIKUBE_BIN         path to the minikube binary (default: minikube)
#   KUBECTL_BIN          path to the kubectl binary   (default: kubectl)
#
# Version note: minikube's own --kubernetes-version=stable does not always
# track the newest Kubernetes minor right after a new release - minikube
# ships its own vetted/tested version list and can fail outright if asked
# for a version its bundled kubeadm images don't have. Rather than hardcode
# a version that may not exist for a given minikube release, this script
# defaults to minikube's "stable" alias and lets you override via
# MINIKUBE_K8S_VERSION if you need to pin a specific minor for compatibility
# testing and your minikube version supports it (check `minikube config
# defaults kubernetes-version` / `minikube start
# --kubernetes-version=v1.x.y --dry-run` first). CKAD content in this repo
# should not depend on a specific patch version of Kubernetes.

set -euo pipefail

MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-clusterdrill}"
MINIKUBE_CPUS="${MINIKUBE_CPUS:-2}"
MINIKUBE_MEMORY="${MINIKUBE_MEMORY:-4g}"
MINIKUBE_DRIVER="${MINIKUBE_DRIVER:-}"
MINIKUBE_K8S_VERSION="${MINIKUBE_K8S_VERSION:-stable}"
MINIKUBE_BIN="${MINIKUBE_BIN:-minikube}"
KUBECTL_BIN="${KUBECTL_BIN:-kubectl}"

# Common install locations, in case this runs non-interactively (e.g. from
# a script or CI job) without a login-shell PATH. An interactive shell on
# this machine already has both on PATH; this is just a safety net so a
# non-interactive invocation doesn't fail solely on a PATH miss.
EXTRA_PATH_DIRS=(
  "/etc/profiles/per-user/${USER:-$(id -un)}/bin"
  "/usr/local/bin"
  "/opt/homebrew/bin"
)
for dir in "${EXTRA_PATH_DIRS[@]}"; do
  if [[ -d "$dir" && ":$PATH:" != *":$dir:"* ]]; then
    PATH="$PATH:$dir"
  fi
done
export PATH

err() {
  echo "bootstrap-minikube.sh: $*" >&2
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  grep '^#' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

if ! command -v "$MINIKUBE_BIN" >/dev/null 2>&1; then
  err "'$MINIKUBE_BIN' not found on PATH."
  err "This script does not install minikube - install it first:"
  err "  https://minikube.sigs.k8s.io/docs/start/"
  err "If minikube is installed somewhere non-standard, set MINIKUBE_BIN=/path/to/minikube."
  exit 1
fi

if ! command -v "$KUBECTL_BIN" >/dev/null 2>&1; then
  err "'$KUBECTL_BIN' not found on PATH."
  err "This script does not install kubectl - install it first:"
  err "  https://kubernetes.io/docs/tasks/tools/#kubectl"
  err "If kubectl is installed somewhere non-standard, set KUBECTL_BIN=/path/to/kubectl."
  exit 1
fi

echo "bootstrap-minikube.sh: using profile '$MINIKUBE_PROFILE'"

# Idempotency check: if the profile already exists and is Running, don't
# call `minikube start` again - it's a safe no-op either way, but skipping
# it avoids the extra time cost and matches "should not fail or recreate
# anything unnecessarily" from the ticket.
EXISTING_STATUS="$("$MINIKUBE_BIN" status -p "$MINIKUBE_PROFILE" --format '{{.Host}}' 2>/dev/null || true)"

if [[ "$EXISTING_STATUS" == "Running" ]]; then
  echo "bootstrap-minikube.sh: profile '$MINIKUBE_PROFILE' is already running - reusing it."
else
  if [[ -n "$EXISTING_STATUS" ]]; then
    echo "bootstrap-minikube.sh: profile '$MINIKUBE_PROFILE' exists but is not running (status: $EXISTING_STATUS) - starting it."
  else
    echo "bootstrap-minikube.sh: no existing profile '$MINIKUBE_PROFILE' found - creating it."
  fi

  START_ARGS=(
    -p "$MINIKUBE_PROFILE"
    --cpus="$MINIKUBE_CPUS"
    --memory="$MINIKUBE_MEMORY"
    --kubernetes-version="$MINIKUBE_K8S_VERSION"
  )
  if [[ -n "$MINIKUBE_DRIVER" ]]; then
    START_ARGS+=(--driver="$MINIKUBE_DRIVER")
  fi

  # `minikube start` is itself idempotent/safe to re-run against a stopped
  # or partially-provisioned profile of the same name - it reconciles
  # rather than recreates from scratch.
  "$MINIKUBE_BIN" start "${START_ARGS[@]}"
fi

# Point kubectl at this profile's context. `minikube start` already does
# this, but this is explicit and cheap, and covers the "already running,
# script just re-run" idempotent path where some other context could have
# been made active in between.
"$MINIKUBE_BIN" update-context -p "$MINIKUBE_PROFILE" >/dev/null 2>&1 || true
"$KUBECTL_BIN" config use-context "$MINIKUBE_PROFILE" >/dev/null

CURRENT_CONTEXT="$("$KUBECTL_BIN" config current-context)"
if [[ "$CURRENT_CONTEXT" != "$MINIKUBE_PROFILE" ]]; then
  err "kubectl context is '$CURRENT_CONTEXT', expected '$MINIKUBE_PROFILE'."
  err "Run: kubectl config use-context $MINIKUBE_PROFILE"
  exit 1
fi

# Keep the local authoring cluster aligned with the question pools that rely
# on Ingress resources and resource metrics. Query all addon states once, then
# only enable the addons that are currently disabled so repeated bootstrap runs
# remain quick and do not unnecessarily reconcile addon resources.
ADDONS_JSON="$("$MINIKUBE_BIN" addons list -p "$MINIKUBE_PROFILE" -o json)"
ADDONS_JSON_FLAT="$(tr -d '\n' <<<"$ADDONS_JSON")"
REQUIRED_ADDONS=(ingress metrics-server)

enable_addon() {
  local addon="$1"

  if ! "$MINIKUBE_BIN" addons enable "$addon" -p "$MINIKUBE_PROFILE"; then
    err "enabling addon '$addon' did not complete on the first attempt - retrying once."
    "$MINIKUBE_BIN" addons enable "$addon" -p "$MINIKUBE_PROFILE"
  fi
}

for addon in "${REQUIRED_ADDONS[@]}"; do
  if grep -Eq "\"${addon}\"[[:space:]]*:[[:space:]]*\{[^}]*\"Status\"[[:space:]]*:[[:space:]]*\"enabled\"" <<<"$ADDONS_JSON_FLAT"; then
    echo "bootstrap-minikube.sh: addon '$addon' is already enabled - skipping."
  else
    echo "bootstrap-minikube.sh: enabling addon '$addon'."
    enable_addon "$addon"
  fi
done

echo
echo "bootstrap-minikube.sh: minikube cluster '$MINIKUBE_PROFILE' is ready."
echo "bootstrap-minikube.sh: kubectl context: $CURRENT_CONTEXT"
echo
"$KUBECTL_BIN" get nodes
echo
echo "bootstrap-minikube.sh: done - ready for lib/verify-question.sh runs."
