# ADR 0010: Sever the candidate's terminal and RBAC grant at exam finalization, before grading

Status: Accepted

## Context

A security audit (2026-10) flagged R11: `session_lifecycle.finalize_exam()`
grades every ungraded question sequentially (`run_check`, up to the
per-check timeout each) once an exam attempt ends - manual submit or the
server deadline scheduler (`_exam_watchdog`, see
[ADR 0006](0006-attempt-lifetime-versus-browser-idle.md)). The candidate's
open terminal stayed live and writable for the entire grading pass. A
candidate racing the clock could keep mutating cluster state in one
question's namespace while an earlier question in the same attempt was
already being graded, or while their own namespace was mid-check.

The obvious-looking fix - revoke `grant_user_namespace_access`'s
namespace-scoped RoleBinding, the mechanism that in principle restricts a
per-user terminal's kubeconfig - turned out not to apply to the live app
at all: [ADR 0008](0008-remove-multi-user-mode.md) made
`users.single_user_mode()` permanently `True`, and
`ttyd_manager._spawn_env()` returns the application's own full,
inherited environment (including its own unrestricted kubeconfig)
unconditionally whenever `single_user_mode()` is true, *before* it ever
reaches the per-user-kubeconfig branch. In the live, single-trusted-
operator app there is no namespace-scoped RoleBinding to revoke, because
one was never granted to begin with - the terminal already has the same
cluster privileges `check.sh`/`setup.sh` themselves run with, by design
(see [Isolation history](../architecture.md#isolation-history)). Revoking
a RoleBinding that doesn't exist closes nothing.

## Decision

`finalize_exam()` now takes two independent actions before grading a
single question, both best-effort (logged, not raised, on failure - a
failure here must not block finalization from completing and recording
whatever `check.sh` actually found):

1. **`ttyd_manager.kill_user_tmux_sessions(user_id)`** - the one that
   actually matters live. A `tmux kill-server` on this `user_id`'s
   private socket tears down every tab's shell outright, severing any
   command already running in it (including a background loop), not
   merely closing the browser's view of it. This is the only mechanism
   available that actually constrains a single-trusted-operator
   terminal, since its cluster credentials cannot be narrowed without
   undermining the single-operator design itself (the terminal is
   *supposed* to have the application's own privileges).
2. **`run_freeze_exam_namespaces()`** (`web/grading_client.py`, backed by
   `lib/grading.sh`'s `freeze_exam_namespaces`) - deletes the
   `clusterdrill-system-access-binding` RoleBinding in every namespace
   (primary and secondary, same `clusterdrill-question` label selector
   [ADR 0002](0002-kubernetes-metadata-conventions.md)/R06 already uses)
   belonging to this attempt's questions. Kept correct as defense-in-depth
   for `grant_user_namespace_access`'s own retained-but-unreachable
   mechanism (same rationale ADR 0008 already applies to that whole
   code path) - not because it does anything in the live app today.

`terminal_router.py`'s existing per-connection revocation watcher (R04,
`_close_if_session_revoked`) gets a sibling, `_close_if_exam_finalizing`,
polling `sessions.is_exam_finalizing(user_id)`. It closes the open
terminal WebSocket (code 4402) the moment finalization starts - a prompt,
intentional close instead of waiting for ttyd's connection to a now-dead
tmux session to error out on its own. The real severing already happened
synchronously in `finalize_exam`, before this watcher ever gets a chance
to fire.

## Consequences

- A candidate's terminal shell is killed outright the instant their exam
  attempt starts finalizing, including when the deadline scheduler
  triggers it with no browser open at all. Any command running in it at
  that moment is terminated; a command that already completed before
  finalization started cannot be undone.
- Namespaces and their contents are not deleted by either action - only
  the shell process and (where it exists) the RoleBinding. `_cleanup_
  finished_session`'s own `run_batch_cleanup` call tears the namespaces
  down shortly after, same as before this change.
- If multi-user mode is ever reintroduced, `run_freeze_exam_namespaces`
  is already correct and effective for that case without further work -
  it was not written for a hypothetical, it is simply not reachable
  today, the same relationship every other piece of retained per-user
  machinery already has to the live app.
- `sessions.is_exam_finalizing()` reads `ActiveSession.finalization_started_at`,
  already written by `finalize_exam()` for its own idempotency checkpoint -
  no new state was introduced to support the terminal-close signal.
- Does not change ADR 0006's idle-expiry decision: browser idle still does
  not kill the terminal or revoke anything. Finalization now does, for the
  specific attempt that is being scored, once scoring has actually begun.
