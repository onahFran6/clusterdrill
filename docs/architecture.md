# Architecture

This is the deep technical map of ClusterDrill: how the pieces fit together
and why, one level below README.md's summary.
Read [README.md's Architecture section](../README.md#architecture) first for the
one-paragraph-per-component overview - this document assumes that context and
goes further into request flow, module wiring, and design rationale.

For *decisions and their alternatives*, see [`docs/adr/`](adr/) - this
document explains the system as it stands; the ADRs explain why a specific
choice (naming, metadata, a scanner exception) was made over another.

- [The web app](#the-web-app)
- [The grading contract](#the-grading-contract)
- [The CLI and appliance lifecycle](#the-cli-and-appliance-lifecycle)
- [Multi-user isolation](#multi-user-isolation)
- [The question bank as data](#the-question-bank-as-data)

## The web app

`web/app.py` is an app factory only: FastAPI lifespan, middleware
registration, router wiring, and one shared exception handler. It used to
hold every route directly (1,292 lines); a 2026-08 restructure moved routes
into `web/routers/` (one module per concern) and question-page
context-building into `web/services/question_view.py`. Read `app.py`'s own
module docstring first - it documents this history and the invariants below
in more detail than is repeated here.

### Request lifecycle (`lifespan` in `app.py`)

On startup, in order:

1. `bank.set_node_count()` / `bank.set_storage_profile()` - derived from the
   in-cluster ServiceAccount (`topology.py`), never a host kubeconfig or a
   browser-supplied value, so a question requiring 2+ nodes or a specific
   storage provisioner can be filtered out of the bank before any route
   exposes it.
2. `rbac.ensure_system_bootstrap()` - creates the `clusterdrill-system`
   namespace and its ClusterRole if missing. Self-healing on every restart,
   not just first boot; runs unconditionally because account/profile storage
   lives in this namespace regardless of single- or multi-user mode.
3. `users.ensure_bootstrap_admin()` - one-time admin account creation from
   `CLUSTERDRILL_PASSWORD`, a no-op once any account exists. Runs after step 2
   so the namespace it writes into is guaranteed to exist.
4. Per-user ServiceAccount provisioning (`rbac.ensure_user_service_account`)
   for every existing account - skipped entirely in single-user mode. An
   identity that can create ClusterRoleBindings can bind cluster-admin, so
   this is deliberately never run against a shared cluster; hosted
   multi-user deployments must isolate each learner in a separate cluster
   instead.
5. `ttyd_manager.start()` - spawns the single app-lifetime `ttyd` subprocess,
   torn down on shutdown so nothing outlives the FastAPI process.
6. An idle-watchdog background task starts (`_idle_watchdog`, polling every
   `IDLE_WATCHDOG_INTERVAL_SECONDS = 15`), active only when the password gate
   is enabled - see [Idle timeout](#idle-timeout) below.

### Middleware order

Starlette wraps middleware in *reverse* registration order, so the
last-registered one is outermost and runs first per request.
Registered first to last (= innermost to outermost) in `app.py`:

1. `auth.PasswordGateMiddleware` - needs `request.session` already populated.
2. `SessionMiddleware` (Starlette's own, itsdangerous-backed) - populates
   `request.session`.
3. `security_headers.SecurityHeadersMiddleware` - outermost, so its headers
   (CSP, etc.) land on every response including the gate's own
   redirects/errors.

The session cookie is added unconditionally, but is a no-op storage layer
when the gate is off - `PasswordGateMiddleware` short-circuits before
touching `request.session` in that case. `SESSION_MAX_AGE_SECONDS` (default
8 hours, `CLUSTERDRILL_SESSION_MAX_AGE_SECONDS` to override) is a hard
ceiling on the signed cookie's own lifetime, independent of and in addition
to the idle watchdog.

### Routers (`web/routers/`)

| Module | Routes | Purpose |
| --- | --- | --- |
| `pages.py` | `GET /`, `/topics`, `/topics/{topic}`, `/practice-tests`, `/progress`, `/mock-exam`, `/sessions/results` | Hub/landing pages. |
| `questions_router.py` | `GET /questions/{qid}`, `POST /questions/{qid}/check`, `POST /questions/{qid}/reset` | The core question view + grading loop. |
| `sessions_router.py` | `POST /sessions/start`, `/sessions/start-boss`, `/sessions/start-daily`, `/sessions/submit`, `/sessions/end` | Session-mode lifecycle (see below). |
| `auth_router.py` | `GET/POST /login`, `POST /logout` | Login form + session cookie issuance. Reachable pre-login even when the gate is on. |
| `admin_router.py` | `GET /admin`, `POST /admin/users`, `/admin/users/{user_id}/reset-password`, `/admin/users/{user_id}/delete` | Admin-only account management - the whole router is gated by `Depends(auth.require_admin)` at the `APIRouter` level, not per-route. |
| `idle_router.py` | `POST /heartbeat`, `GET /idle-status` | Client-side idle tracking, feeds `idle.py`'s tracker. |
| `terminal_router.py` | `WS /terminal/t/{tab_id}/{path}`, `WS /terminal/{path}` (legacy, no tab id) | Reverse-proxies ttyd's websocket; validates the `Origin` header itself since browsers don't enforce same-origin on WebSocket upgrades. |
| `health.py` | `GET /healthz` | Question-count health check, reachable pre-login. |

State-changing POST routes are protected by CSRF (`auth.csrf_protect_form`
for HTML `<form>` posts, `auth.csrf_protect_header` for `fetch()`-driven JSON
posts) as an explicit `Depends(...)` per route, not blanket middleware -
each router declares which of its own routes need it.

### The question-view request

`GET /questions/{qid}` is the one route most of the app exists to serve.
`web/services/question_view.py`'s `question_context()` does the actual
work; `questions_router.py`'s route handler is a thin wrapper:

1. Resolve the active session (if any) so Previous/Skip/progress-bar
   navigation walks the *session's* qid list rather than the full flat bank
   - `question_context()` documents its own fallback behavior for a qid
     outside any active session.
2. Auto-provision on first view: if the question's namespace doesn't exist
   yet, run its `setup.sh` before rendering (keyed by `user_id`, so one
   learner's provisioning never touches another's namespace).
3. Read `QUESTION.md`, its Hint section, `ANSWER.md`, and `diagram.mmd` from
   disk and hand them to the Task/Hint/Solution/Diagram tabs. Diagram content
   is read server-side but rendered client-side by Mermaid.js (loaded from a
   CDN in `question.html`) - `app.py` never renders Mermaid itself.
4. Render `question.html`, which embeds the ttyd terminal as an iframe and
   wires the "Check" button to `POST /questions/{qid}/check` via a small
   fetch call in `static/app.js` (the only place this app uses client-side
   JS beyond DOM updates for the live checklist - no SPA framework, no build
   step).

### Grading integrity invariant

**The only source of PASS/FAIL/score data is `check.sh`'s live stdout,
parsed by `grading_client.py`.** There is no endpoint anywhere in this app
that accepts a client-supplied "mark as done" flag - see
[The grading contract](#the-grading-contract) below for the parsing format
itself. `profile_store.py` (XP, speed tier, achievement unlocks) is only
ever updated *after* `grading_client.run_check()` produces a real pass/fail,
never speculatively.

### Session modes (`sessions.py`, `sessions_router.py`)

A "session" is a concrete, ordered qid list plus a mode, replacing
navigation over the full flat question bank. Modes: **fixed** (all questions
in one topic, up to `SESSION_SIZE`), **randomized** (random subset of one
topic), **mixed** (random subset across topics), **exam** (timed, graded at
the end rather than per-question), **boss** (small pool, HP/damage model
tied to wrong answers), **daily** (small cross-topic pool that refreshes per
visit). Starting a session (`POST /sessions/start` and its `-boss`/`-daily`
variants) makes it the single active session for that user; `question_view.py`
is what actually reads "is there an active session" on every question view.

### Idle timeout

`idle.py` tracks activity independently of the session cookie's own max-age.
The watchdog in `app.py` (`_idle_watchdog`, `_perform_idle_kill`) only acts
when the password gate is enabled - idle-kill is meaningless for local dev
or an SSH-tunnel deployment, which already have their own trust boundary
(your machine, your SSH key) and no login to revoke. On timeout it clears
all sessions, revokes login cookies, and kills tmux sessions
(`ttyd_manager.kill_all_tmux_sessions`) via `asyncio.to_thread` so the
synchronous, sequential `tmux kill-session` calls never stall the single
event loop this whole app runs on.

### Terminal (`ttyd_manager.py`)

A single long-lived `ttyd` process is spawned on FastAPI startup and bound
to loopback only (127.0.0.1) - never exposed on its own port, only reachable
through `terminal_router.py`'s reverse proxy. Multi-tab support runs
separate tmux sessions per `(user_id, tab_id)`, slot-allocated so
reconnecting users don't collide on ports. On first terminal access for a
given question, the tab's shell `cd`s into that question's working
directory (`$HOME/practice-work/<qid>`, the same path `lib/grading.sh`'s
`question_workdir()` uses - see [The grading contract](#the-grading-contract)).
Nothing in this app reads ttyd's terminal output or wires it into `check.sh`
criteria in any way; it is purely an additive UI surface for the candidate's
own convenience.

### State storage: Kubernetes objects, not a database

Per-user profile/achievement progress lives as ConfigMaps
(`profile_store.py`) and accounts as Secrets (`users.py`), both in
`clusterdrill-system` - read/written via `kubectl get`/`apply` through
`kube_json.py`, not a separate database dependency. This is a deliberate
consequence of [ADR 0001](adr/0001-naming-standard.md): no CRD group is
confirmed as owned by this project yet, so state uses the core
ConfigMap/Secret API instead of a custom type.

## The grading contract

Every question's `setup.sh` and `check.sh` source `lib/grading.sh`, which
defines the parsing contract both `verify-question.sh` and the web UI
(`grading_client.py`) rely on:

- `check_criterion "<description>" <command...>` runs a command and prints
  `CRITERION: <description> = PASS` or `= FAIL` - a stable, line-oriented
  format, not just log output.
- `print_score` must be the last line every `check.sh` emits:
  `SCORE: <passed>/<total>`.
- `full_reset <question_id>` is the only reset path (no soft-reset exists on
  purpose): deletes the question's namespace and anything cluster-scoped
  labeled `clusterdrill-question=<qid>`, waiting for both before returning
  so a subsequent `setup.sh` never races a `Terminating` namespace.
- `apply_default_resource_limits <namespace>` applies a mandatory
  ResourceQuota + LimitRange pair to every question namespace except the two
  questions that are themselves about authoring a LimitRange - see the
  function's own comment in `lib/grading.sh` for the exact sizing rationale.
- `grant_user_namespace_access <namespace> <user_id>` is what actually
  prevents one learner's terminal from reading another's namespace directly
  - see [Multi-user isolation](#multi-user-isolation).

`check.sh` never uses `set -e` (a failing criterion must not abort the rest
of the checklist) and may only assert against **live cluster state** - never
a client-supplied "done" flag. `lib/verify-question.sh` is the automated
proof that a question's `setup.sh`/`check.sh`/`ANSWER.md` are all correct
*together*: reset (expect score 0) -> apply `ANSWER.md`'s reference solution
(expect full score) -> reset again (expect no leaked cluster-scoped
objects). See [CONTRIBUTING.md](../CONTRIBUTING.md#verify-before-opening-a-pr)
for how to run it.

## The CLI and appliance lifecycle

`clusterdrill/cli.py` implements everything under `clusterdrill local
<command>`:

| Command | What it does |
| --- | --- |
| `doctor` | Read-only: checks Docker health, the Minikube profile's driver/node count, default StorageClass, and RBAC (`kubectl auth can-i`) - changes nothing, ever. |
| `bootstrap` | Installs the Minikube binary itself, only after explicit acknowledgement. |
| `init` | Creates or reuses the dedicated `clusterdrill` Minikube profile; reads Docker's available CPU/memory (`docker_capacity()`) to pick resource defaults. |
| `install` | Renders `manifests/local-appliance.yaml` (`render_manifest()`) with the resolved image/password/version and applies it - or, with `--installer=helm`, calls `install-helm` instead. |
| `install-helm` | Renders and installs the Helm chart at `helm/clusterdrill/` with equivalent values. |
| `url` | Opens a `minikube service` tunnel and supervises it in the foreground. |
| `smoke-test` | Confirms the deployed `/healthz` endpoint responds `ok`. |
| `destroy` | Deletes only the `clusterdrill` Minikube profile. |

Image resolution (`clusterdrill/release.py`) maps an installed package
version to a digest-pinned image via `release_manifest.json`, falling back
to `clusterdrill:dev` - see [README's Release policy](../README.md#release-policy)
for why `--image clusterdrill:dev` (built from your own checkout) is the
recommended path today rather than the resolved default.

`clusterdrill/manifests/local-appliance.yaml` and
`clusterdrill/helm/clusterdrill/` are two independent renderings of the same
object set (Namespace, ServiceAccount, Secret, ClusterRole,
ClusterRoleBinding, Deployment, Service) - `clusterdrill/tests/test_helm_chart.py`
enforces byte-for-byte metadata/RBAC parity between them, per
[ADR 0002](adr/0002-kubernetes-metadata-conventions.md). They differ in one
place tests don't pin down: the raw manifest's Service is `ClusterIP` (it's
built around `local url`'s `minikube service` tunnel), while the chart's is
`NodePort` (`clusterdrill/helm/clusterdrill/templates/service.yaml`) - it's
meant to be reachable directly once installed somewhere `local url` can't
reach.

Both renderings are themselves cluster-agnostic - nothing in either YAML
assumes Minikube. What's Minikube-locked is the CLI wrapper around them:
`PROFILE = "clusterdrill"` (`cli.py:18`) and `profile_kubectl()`
(`cli.py:134-141`) hardcode every `install`/`url`/`smoke-test`/`destroy`
kubectl call to `--context clusterdrill`, and `install-helm` does the same
with `--kube-context` (`cli.py:659`) - there is no `--context`/`--kubeconfig`
flag on any subcommand. Installing onto a cluster the CLI didn't create
means driving the Helm chart or the raw manifest directly instead of
through `clusterdrill local install` - see
[README's Installing on a cluster you already have](../README.md#installing-on-a-cluster-you-already-have).

`deploy/entrypoint.sh` is unrelated to either of those: it is the container
image's own `ENTRYPOINT` (wired in `Dockerfile`), not part of the CLI's
appliance-lifecycle flow. It generates an in-cluster kubeconfig from the
pod's own ServiceAccount token, creates the runtime directories the app
expects (`~/.kube`, `~/.clusterdrill/kubeconfigs`, `~/practice-work`), and
execs `uvicorn app:app` from `/opt/clusterdrill/web`. If you're looking for
"how does the appliance get deployed," that's `local-appliance.yaml`/the
Helm chart, not this file - this file is "what the container runs once
it's already scheduled."

## Multi-user isolation

Classroom/multi-user mode (still experimental, gated behind its own opt-in)
layers three independent mechanisms, each answering a different question:

1. **Where does a user's data live?** Every question namespace and every
   cluster-scoped object is labeled `clusterdrill-question=<qid>`; combined
   with `apply_default_resource_limits`, one account cannot starve another
   by running something unbounded in its own namespace.
2. **Who can this account act as, cluster-wide?** `rbac.py` provisions one
   ServiceAccount per account (`ensure_user_service_account`), never
   cluster-admin, and only in multi-user mode - see `app.py`'s lifespan
   step 4 above.
3. **What can this account's own terminal actually reach?**
   `grant_user_namespace_access` grants a namespace-scoped Role+RoleBinding
   to that one ServiceAccount for that one namespace, and `ttyd_manager.py`
   points that user's terminal at a kubeconfig authenticating as that
   ServiceAccount - instead of the app's own admin kubeconfig, which
   `check.sh`/`setup.sh` themselves still use, unaffected. Without this
   third mechanism, mechanism 1 alone would still let one learner's shell
   run `kubectl get pods -n <another-learners-namespace>` directly, since
   every terminal would otherwise share the same cluster-admin credential.

## The question bank as data

Questions are plain folders (`questions/<topic>/qNNN-slug/`), not database
rows - see [CONTRIBUTING.md](../CONTRIBUTING.md#folder-shape) for the exact
shape and [README's Layout](../README.md#layout) for the full directory
tree. Two things worth knowing that aren't in either of those:

- `web/questions.py` discovers the bank from disk at startup (parsing every
  `QUESTION.md` and topic's `domains.fragment.yaml`) and is also imported
  directly by `clusterdrill/cli.py`'s `question_bank_report()` - the CLI's
  own `doctor`/`install` output about "N questions excluded by storage
  profile" comes from the same discovery code the web app uses, not a
  separate count.
- `lib/load-domains.sh` merges every topic's `domains.fragment.yaml` into
  `.generated/domains.yaml` and cross-checks that every `QUESTION.md`/
  `check.sh` pair is actually represented in some fragment - this is what
  `lib/load-domains.sh --check` validates in CI, not just documentation
  about the expected shape.
