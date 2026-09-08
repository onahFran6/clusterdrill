# shellcheck shell=bash
# Installed at /etc/profile.d/clusterdrill-aliases.sh - sourced (not
# executed) by /etc/profile's own run-parts loop for every login shell.
# ttyd's terminal
# spawns tmux, and tmux's default shell is invoked as a login shell
# (confirmed empirically: `-bash`, leading dash) - so this is the one place
# that reaches every terminal tab regardless of deployment path (local
# Minikube, standalone Helm, or clusterdrill-lab).
#
# `alias k=kubectl` plus completion for it mirrors exactly what a real
# proctored CKAD exam environment provides - no extra shortcut aliases
# (kgp, kgs, ...), since those aren't part of the real exam setup either
# and this project's whole premise is practicing under exam-realistic
# conditions.
#
# Guarded so it's a no-op if this file is ever sourced by a non-bash login
# shell (`alias`/`complete` are bash builtins, not POSIX sh) or a
# non-interactive one (alias expansion is off there anyway, and it would
# otherwise add a `kubectl` subprocess call to every non-interactive login
# invocation for no benefit).
if [ -n "${BASH_VERSION-}" ]; then
  case "$-" in
    *i*)
      alias k=kubectl
      eval "$(kubectl completion bash)"
      complete -o default -F __start_kubectl k
      ;;
  esac
fi
