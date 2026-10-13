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
- [Isolation history](#isolation-history)
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
   is enabled - see [Idle timeout and attempt lifetime](#idle-timeout-and-attempt-lifetime) below.
7. An exam-deadline task starts (`_exam_watchdog`, polling every
   `EXAM_WATCHDOG_INTERVAL_SECONDS = 1`) whether or not the password gate is
   on. It finalizes due exams through the same path as Submit Exam.
8. `_startup_cluster_sweep()` is scheduled as a background task, not
   awaited - sweeps every known account's namespaces/cluster-scoped
   objects, cleaning up anything a prior process's crash/redeploy left
   stranded. Fire-and-forget so Uvicorn can bind its socket and start
   answering `/healthz` immediately rather than blocking `lifespan()`
   past the liveness probe's deadline. `readiness.mark_sweep_complete()`
   fires once this finishes (success or failure per account) - `/readyz`
   (the **readiness**Probe target, not `/healthz`'s liveness one) 503s
   until then, so a freshly started pod never receives new sessions until
   cleanup is actually done. The Deployment's `strategy: Recreate` (both
   manifests) closes the other half of this race: it fully terminates the
   old pod before this one starts, so by the time this sweep runs, there
   is no still-live pod whose active session it could mistake for orphaned
   state (R10).

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
| `pages.py` | `GET /`, `/topics`, `/topics/{topic}`, `/practice-tests`, `/progress`, `/mock-exam`, `/sessions/results` | Hub/landing pages; `/practice-tests` redirects to the unified Practice library at `/topics`. |
| `questions_router.py` | `GET /questions/{qid}`, `POST /questions/{qid}/check`, `POST /questions/{qid}/reset` | The core question view + grading loop. |
| `sessions_router.py` | `POST /sessions/start`, `/sessions/start-boss`, `/sessions/start-daily`, `/sessions/submit`, `/sessions/end` | Session-mode lifecycle (see below). |
| `auth_router.py` | `GET/POST /login`, `POST /logout` | Login form + session cookie issuance. Reachable pre-login even when the gate is on. |
| `admin_router.py` | `GET /admin`, `POST /admin/users`, `/admin/users/{user_id}/reset-password`, `/admin/users/{user_id}/delete` | Admin-only account management - the whole router is gated by `Depends(auth.require_admin)` at the `APIRouter` level, not per-route. |
| `idle_router.py` | `POST /heartbeat`, `GET /idle-status` | Client-side idle tracking, feeds `idle.py`'s tracker. |
| `terminal_router.py` | `WS /terminal/t/{tab_id}/{path}`, `WS /terminal/{path}` (legacy, no tab id) | Reverse-proxies ttyd's websocket; validates the `Origin` header itself since browsers don't enforce same-origin on WebSocket upgrades. |
| `health.py` | `GET /healthz`, `GET /readyz` | `/healthz` is always-instant (liveness; also reachable pre-login). `/readyz` (readiness only) 503s until this process's startup cluster sweep finishes - see [Request lifecycle](#request-lifecycle-lifespan-in-apppy) step 8 (R10). |

The Practice library progressively enhances topic links with an adjacent session-setup panel.
It fetches the existing topic page and reuses its server-rendered form; without JavaScript, links open that page normally.
Topic switches cancel stale requests, and loading forms cannot be submitted until their settings are ready.
Practice and exam forms accept custom positive question counts and whole-minute timers from 1 to 240 minutes.
The session-start route rejects invalid explicit values before replacing an active session; the session builder caps question counts to the matching pool.
The existing default counts, default timers, and legacy `all` practice requests remain supported.

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
4. Render `question.html` and wire the practice "Check" button to `POST /questions/{qid}/check` through `static/app.js`.
   The same-origin `static/workspace-preferences.js` runs in the document head, before the workspace paints.
   It validates the versioned `clusterdrill-workspace-v2` localStorage preference and migrates legacy pixel tracks to bounded fractions.
   These display preferences are shared by tabs and accounts on the same browser origin; they are not authorization or attempt state.
   CSS applies the fractions in the wide workspace and uses document flow below 1100px or 650px viewport height.
   A hidden terminal gives the task the workspace width and ignores saved pane sizes.
   The initial ttyd iframe carries its URL as data and receives a `src` only when the terminal is shown.
   Hiding an already connected terminal retains its iframe until navigation; it never shuts down ttyd, kills tmux, or changes session lifetime.
   Question provisioning still occurs before rendering, regardless of terminal visibility.
   Reset layout restores sizing defaults without changing visibility or the attempt.

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

While a user's exam is active, `questions_router.check_question` rejects interim grading with HTTP 403 before invoking a grader or recording progress.
The rule covers every question for that user, including questions outside the exam selection; other users' practice sessions are unaffected.
`question_view.py` forces reference-tab requests back to Task, discards hints, and skips answer and diagram loading.
The exam template omits all reference panels, embedded diagram data, the grading checklist, and its divider; its task occupies one grid row regardless of saved practice sizing.
The dedicated `POST /sessions/submit` path still grades the selected questions at submission.
See [ADR 0005](adr/0005-active-exam-reference-restrictions.md) for the restriction's scope and limitations.

A failed question setup exposes Retry setup and an accessible status message inside the provisioning banner, including during an exam.
A successful retry records the question as provisioned so navigation does not rerun setup over the learner's work.
In an exam, the recovery button disappears after success; ordinary Reset is not rendered after successful provisioning.

**Exam scoring and selection model (I06), stated explicitly rather than
left implicit:** `start_exam`'s draw is a uniform `random.shuffle` + slice
over the filtered pool (topics/difficulty/`exam_eligible` applied first) -
it does not stratify the sample to match the real CKAD curriculum's
published per-domain weight percentages, and two draws of the same size
from the same filters will not generally contain the same per-domain mix.
`finalize_exam`'s score is a simple count of fully-passed questions
(`sum(passed for q in questions)`) - a question's `points` fragment field
is cosmetic display only (the "N pts" pill on the question page) and does
not weight the final score, and a question with some but not all
criteria passing counts as a plain fail, not partial credit. The "By
domain" breakdown on the results page is "% of *this attempt's sampled*
questions in that domain that were passed," not a statement about how
that domain's official CKAD weight was represented in the sample. None of
this is a bug - it is a documented product decision, not a correctness
gap - but a candidate comparing their percentage against the real exam's
published domain weights should know the two numbers answer different
questions.

### Idle timeout and attempt lifetime

`idle.py` tracks activity independently of the session cookie's own max-age.
The watchdog in `app.py` (`_idle_watchdog`, `_perform_idle_kill`) only acts
when the password gate is enabled - idle-kill is meaningless for local dev
or an SSH-tunnel deployment, which already have their own trust boundary
(your machine, your SSH key) and no login to revoke. On timeout it revokes
login cookies and kills embedded tmux sessions
(`ttyd_manager.kill_all_tmux_sessions`) via `asyncio.to_thread` so the
synchronous, sequential `tmux kill-session` calls never stall the single
event loop this whole app runs on. It leaves the active practice or exam
attempt in place. Hiding the terminal does not pause that clock, and work
in an external shell does not count as browser activity.

Exam deadlines stay server-authoritative. `_exam_watchdog` finalizes a due
exam even when the browser is closed, through the same
`session_lifecycle.finalize_exam()` path as manual Submit Exam. Re-login
resumes an unexpired attempt at its last question, or opens the stored
result when the deadline has already been graded. The attempt store is
still in memory, so a process restart drops it. Browser logout does not
revoke SSH or Kubernetes credentials the learner holds outside the app.
See [ADR 0006](adr/0006-attempt-lifetime-versus-browser-idle.md).

`finalize_exam()` itself severs the candidate's terminal before it grades
a single question: `ttyd_manager.kill_user_tmux_sessions(user_id)` kills
that user's tmux server outright, ending any command still running in it.
This is the mechanism that actually matters in the live
single-trusted-operator app (see [Isolation history](#isolation-history)) -
the terminal there inherits the application's own full kubeconfig
directly, with no narrower per-namespace RBAC grant to revoke instead.
`finalize_exam()` also calls `run_freeze_exam_namespaces()`, which revokes
`grant_user_namespace_access`'s namespace-scoped RoleBinding - correct
defense-in-depth for that retained-but-unreachable per-user mechanism, but
currently a no-op live, since that RoleBinding is never granted to begin
with under `single_user_mode()`. `terminal_router.py`'s revocation watcher
(R04) also closes the open terminal WebSocket the instant finalization
starts, as a prompt signal following the kill that already happened. See
[ADR 0010](adr/0010-revoke-rbac-at-exam-finalization.md).

### Terminal (`ttyd_manager.py`)

A single long-lived `ttyd` process is spawned on FastAPI startup and bound
to loopback only (127.0.0.1) - never exposed on its own port, only reachable
through `terminal_router.py`'s reverse proxy. Multi-tab support runs
separate tmux sessions per `(user_id, tab_id)`, slot-allocated so
reconnecting users don't collide on ports. On first terminal access for a lab-workspace tab, the shell `cd`s into
that question's working directory (`$HOME/practice-work/<qid>`, the same
path `lib/grading.sh`'s `question_workdir()` uses - see
[The grading contract](#the-grading-contract)).
Nothing in this app reads ttyd's terminal output or wires it into `check.sh`
criteria in any way; it is purely an additive UI surface for the candidate's
own convenience.

A worker-node tab is not that lab shell. `ensure_session()` does not create
a plain tmux session for it and does not send `cd`, because `tmux new-session -A`
would attach to that plain session and skip the node command. The pane
command itself turns mouse mode on, then runs `kubectl debug`. Successful
`chroot /host` still depends on the debug pod's security context; constructing
the command does not prove the shell reached the node. The question page's
"Use your own terminal" disclosure shows the resolved namespace and the
application workspace path. The copyable container exec command is rendered
whenever the pod identity env vars are present (`users.single_user_mode()` is
now unconditionally True - see [Isolation history](#isolation-history)),
which the local appliance manifest sets and the Helm chart does not.
That command enters the application container with the application's cluster
privileges. It is not a restricted learner shell, and it is not a path on the
node.

Copy-to-clipboard is the one place this app *does* read something out of a
terminal, and only that: `ensure_session` turns tmux's own mouse mode on
(fixes a real scroll-wheel-vs-shell-history bug), which as a side effect
means a plain click-drag is captured by tmux instead of becoming a native
browser text selection - there is nothing for the browser to copy on its
own. `terminal_proxy_http_tab` injects `static/terminal-copy-bridge.js` into
ttyd's own served page (a text replace before `</body>` - ttyd ships its
whole UI as one embedded, minified bundle, there's no template to hook into
otherwise); that script notices a real mouse-drag and calls
`POST /terminal-clipboard/{tab_id}`, which reads back whatever tmux's
default drag-release binding already copied into that user's own tmux paste
buffer (`ttyd_manager.read_paste_buffer`) and pushes it into the real
browser clipboard. Reads a per-user tmux paste buffer via the per-user tmux
socket mechanism described in [Isolation history](#isolation-history) -
retained infrastructure, not a live multi-tenant guarantee (see that
section for why): tmux paste buffers are server-wide, not per-session, so
this would leak another candidate's clipboard text on a shared server (see
[ADR 0004](adr/0004-per-user-tmux-socket.md)).

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
- `grant_user_namespace_access <namespace> <user_id>` scopes a second
  identity's terminal to one namespace - part of the retained-but-unreachable
  machinery covered in [Isolation history](#isolation-history).

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
| `install-helm` | Renders and installs the Helm chart at `helm/clusterdrill-chart/` with equivalent values. |
| `url` | Opens a `minikube service` tunnel and supervises it in the foreground. |
| `smoke-test` | Confirms the deployed `/healthz` endpoint responds `ok`. |
| `destroy` | Deletes only the `clusterdrill` Minikube profile. |

Image resolution (`clusterdrill/release.py`) maps an installed package
version to a digest-pinned image via `release_manifest.json`, falling back
to `clusterdrill:dev` - see [README's Release policy](../README.md#release-policy)
for why `--image clusterdrill:dev` (built from your own checkout) is the
recommended path today rather than the resolved default.

`clusterdrill/manifests/local-appliance.yaml` and
`clusterdrill/helm/clusterdrill-chart/` are two independent renderings of the same
object set (Namespace, ServiceAccount, Secret, ClusterRole,
ClusterRoleBinding, Deployment, Service) - `clusterdrill/tests/test_helm_chart.py`
enforces byte-for-byte metadata/RBAC parity between them, per
[ADR 0002](adr/0002-kubernetes-metadata-conventions.md). They differ in one
place tests don't pin down: the raw manifest's Service is `ClusterIP` (it's
built around `local url`'s `minikube service` tunnel), while the chart's is
`NodePort` (`clusterdrill/helm/clusterdrill-chart/templates/service.yaml`) - it's
meant to be reachable directly once installed somewhere `local url` can't
reach.

The chart is also independently published as an OCI artifact
(`oci://registry-1.docker.io/w00dson/clusterdrill-chart`, built by
`.github/workflows/release-image.yml` on every release tag) - a real
external distribution channel now exists alongside the CLI-driven path,
not just cluster-agnostic in principle.

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

## Isolation history

`users.single_user_mode()` is unconditionally `True`. There is no
`CLUSTERDRILL_SINGLE_USER` toggle, no classroom/multi-user mode, and no
supported way to create a second account: `create_user()` only ever lets
the one bootstrap `admin` account through. This is a deliberate removal,
not a default, decided after a security audit (2026-10) found that the
isolation mechanisms below - while real, independently-correct code -
never actually delivered what "multi-user mode" implied:

- A learner's terminal shared the application's own OS user, filesystem,
  and process environment; a kubeconfig-provisioning failure silently fell
  back to the application's own unrestricted kubeconfig rather than
  refusing the terminal outright.
- Every provisioned account could create arbitrary Pods in the
  application's own `clusterdrill-system` namespace (Kubernetes RBAC
  cannot scope `create` by resource name), which can mount that
  namespace's Secrets and service-account tokens.

Supporting untrusted learners safely needs a separate execution boundary
per learner (a disposable cluster each), not more RBAC layered onto one
shared appliance - see the audit's F02 disposition. The supported shape is
one trusted operator per dedicated disposable cluster, full stop.

The per-account isolation machinery below is **retained in the codebase,
unreachable in the supported app** (`single_user_mode()` short-circuits
before any of it runs) - kept as working, tested infrastructure rather than
deleted outright, not as a currently-active guarantee. Four independent
mechanisms, each answering a different question:

1. **Where would a user's data live?** Every question namespace and every
   cluster-scoped object is labeled `clusterdrill-question=<qid>`; combined
   with `apply_default_resource_limits`, one account couldn't starve
   another by running something unbounded in its own namespace.
2. **Who could an account act as, cluster-wide?** `rbac.py` provisions one
   ServiceAccount per account (`ensure_user_service_account`), never
   cluster-admin - but, per the audit, with an unrestricted Pod-create
   grant in the shared system namespace alongside it (see above).
3. **What could an account's own terminal reach?**
   `grant_user_namespace_access` RoleBinds the built-in `admin` ClusterRole
   into that one namespace for that one ServiceAccount (creating a local
   wildcard Role is forbidden by Kubernetes RBAC escalation checks against
   the least-privilege appliance identity - the appliance ClusterRole
   therefore also holds `bind` on `admin`), and `ttyd_manager.py` pointed
   that user's terminal at a kubeconfig authenticating as that
   ServiceAccount - instead of the app's own admin kubeconfig, which
   `check.sh`/`setup.sh` themselves still use, unaffected. On its own,
   mechanism 1 would still let one learner's shell run `kubectl get pods -n
   <another-learners-namespace>` directly, since every terminal otherwise
   shares the same cluster-admin-adjacent credential - but see the shared-OS-user
   caveat above for why this boundary didn't actually hold either.
4. **Could one account reach into another's live shell?** Each user's tmux
   sessions lived on their own private tmux server - `ttyd_manager.py`
   passes `-L clusterdrill-<slot>` (the same per-user slot number that
   already scopes ports) to every tmux invocation, rather than the shared
   default socket. Session names alone (`clusterdrill-<user_id>-<tab_id>`)
   aren't sufficient: on one shared server they're still just names, and
   any candidate's own shell could run `tmux attach -t <name>` against any
   session on that server regardless of who created it. A private socket
   per user makes a session on one socket genuinely invisible and
   unattachable from another - see ADR
   [0004](adr/0004-per-user-tmux-socket.md) for how this was found and
   verified. Still doesn't address the shared-OS-user caveat above (a
   candidate could read another's kubeconfig/files directly, without ever
   needing to attach to their tmux session at all).

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

### Public topic grouping

Question discovery maps versioned source folders onto stable public topics using `TOPIC_ALIASES` in `web/questions.py`.
Pods join Pod Design, Deployments join Deployment Strategies, Services and Ingress/Network Policies join Services Networking, and Storage joins State Persistence.
Container Images and Jobs/CronJobs remain independent topics without version suffixes.
Question IDs, source paths, metadata, and licensing boundaries remain unchanged; progress continues to be calculated from the same question IDs.
Legacy topic URLs redirect to the combined topic, and session submissions normalize legacy topic names.
The practice hub offers one-topic setup and a selected-topic mix within the same column.
One-topic setup uses a topic dropdown, with visible loading feedback and cancellation of superseded requests.
Selected-topic setup renders checkboxes and per-topic difficulty counts on the server; the browser sums those counts to update the matching pool and question limit.
Mixed submissions accept repeated `topics` fields, normalize aliases, and reject unknown topics before replacing an active session.
The selected-topic form sends `topic_scope=selected` so clearing every checkbox is rejected rather than silently drawing from all topics.
Legacy mixed submissions without a topic selection continue to draw from the whole bank.
See [ADR 0007](adr/0007-public-topic-grouping.md).
