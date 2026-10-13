# ADR 0008: Remove multi-user/classroom mode as a supported capability

Status: Accepted

## Context

A security audit (2026-10) of the shared-terminal/shared-RBAC design
documented in [ADR 0004](0004-per-user-tmux-socket.md) and
`docs/architecture.md`'s former "Multi-user isolation" section found two
confirmed, critical gaps that no amount of further RBAC hardening closes:

- Every provisioned learner's terminal ran as the same OS user as the
  application itself, sharing its filesystem, process environment, and
  loopback network. A per-user kubeconfig-provisioning failure silently
  fell back to the application's own unrestricted kubeconfig rather than
  refusing the terminal - and even when provisioning succeeded, a learner's
  shell could still read the application's own kubeconfig/service-account
  token directly off disk, or connect to another user's loopback ttyd port.
- Every provisioned learner could create arbitrary Pods in the
  application's own `clusterdrill-system` namespace (Kubernetes RBAC
  cannot scope `create` by resource name the way it can `get`/`delete`),
  which can select the application's own ServiceAccount or mount that
  namespace's Secrets.

Kubernetes RBAC cannot safely delegate ClusterRoleBinding-adjacent,
cluster-scoped CKAD exercises among mutually untrusted users sharing one
OS process and one cluster - no combination of namespace labels, per-user
ServiceAccounts, RoleBindings, or per-user tmux sockets (ADR 0004) changes
that, because the actual trust boundary that matters (the OS process and
its filesystem) was never per-user to begin with.

## Decision

Remove multi-user/classroom mode as a supported capability, not merely
default it off. `users.single_user_mode()` is now unconditionally `True` -
there is no `CLUSTERDRILL_SINGLE_USER` environment variable, and
`create_user()` only ever lets the one bootstrap `admin` account through.
The `/admin` page and account-creation route remain in the codebase but
are now permanently unreachable (`single_user_mode()` 404s/403s them
unconditionally) rather than deleted outright - the reset-password and
delete-account routes stay live (useful for the one admin resetting their
own password, or recovering from a stray leftover account), gated the same
way they always were.

The per-account isolation machinery (`rbac.py`'s per-user ServiceAccount
provisioning, `ttyd_manager.py`'s per-user tmux socket and kubeconfig
redirection) is left in place rather than deleted - it is real, correct,
independently-tested code, just unreachable through the supported app now.
Tests that exercised it directly do so by monkeypatching
`single_user_mode()` back to `False`, documented as testing that code on
its own terms, not characterizing current app behavior.

Two concrete bugs in that retained code were still fixed, since "unreachable
today" isn't "permanently unreachable" and the code is worth keeping
correct: `ttyd_manager._spawn_env` now actively clears an inherited
`KUBECONFIG` instead of silently leaving the application's own kubeconfig
in place when per-user provisioning fails (previously only logged a
warning).

The supported shape is one trusted operator per dedicated disposable
cluster. Supporting untrusted learners requires a separate execution
boundary per learner - a disposable cluster each - not more RBAC layered
onto one shared appliance process.

## Consequences

- `clusterdrill/manifests/local-appliance.yaml`'s `CLUSTERDRILL_SINGLE_USER`
  env var was removed (it was already set to `"true"` there, but is now a
  dead/no-op setting either way - the Python side no longer reads it at
  all).
- The admin UI's "add a second user" capability is gone; ~24 tests that
  exercised multi-account admin flows were rewritten (to seed accounts
  directly into a fake cluster rather than through the removed API,
  preserving coverage of e.g. the last-admin-deletion guardrail and
  delete's cascade teardown) or removed where they tested the now-dead
  create-a-second-account path itself.
- `docs/architecture.md`'s "Multi-user isolation" section was rewritten as
  "Isolation history" - explaining what existed, why it was removed, and
  that the underlying mechanisms are retained-but-unreachable rather than
  deleted.
- No change to the no-accounts (password gate off) path, or to the one
  bootstrap admin account's own behavior.
