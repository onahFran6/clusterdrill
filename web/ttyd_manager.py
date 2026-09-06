"""Spawns and supervises `ttyd` subprocess(es) for the app's
whole lifetime.

Tab 1 starts on app startup. Tabs 2–N start lazily when the user clicks +.
Each tab is a separate ttyd port + separate tmux session (independent shells),
matching KodeKloud-style "Terminal 1 / Terminal 2 / +" UX.

Tabs are scoped by (user_id, tab_id),
not tab_id alone - two logged-in accounts opening "Tab 1" would otherwise share
one port and one tmux session (literally the same shell). Each user_id is lazily assigned a stable,
process-lifetime "slot" number the first time any of their tabs is touched
(_user_slot below); that slot picks which MAX_TERMINAL_TABS-wide block of
ports it gets, and the tmux session name embeds the user_id directly.
user_id=None (password gate off, no accounts) is pre-assigned slot 0, so
ports 7681..7681+MAX_TERMINAL_TABS-1 and tmux names "clusterdrill-N" are
byte-for-byte unchanged from before this phase in that mode.

_spawn_env(user_id) also points a real
user's ttyd process at that user's RBAC-restricted kubeconfig (rbac.py)
instead of the app's own admin one - separate ports/tmux sessions alone
only stopped two users from *typing in the same shell*, not from one
user's shell reading another user's namespace via kubectl.
"""
from __future__ import annotations

import logging
import os
import shlex
import shutil
import subprocess
import threading
import time
from dataclasses import dataclass, field

import rbac
import users
from kube_json import SYSTEM_NAMESPACE

logger = logging.getLogger("clusterdrill.ttyd")

TTYD_HOST = "127.0.0.1"
TTYD_BASE_PORT = 7681
TTYD_FALLBACK_SHELL = "bash"
MAX_TERMINAL_TABS = int(os.environ.get("CLUSTERDRILL_TERMINAL_MAX_TABS", "5"))
STARTUP_WAIT_SECONDS = 3.0
STARTUP_POLL_INTERVAL = 0.1

# Module-level (not per-TtydPool) so a bare TtydInstance(tab_id=N,
# user_id=X) constructed without going through a pool still computes the
# same port a pool-managed instance for that same user would - see
# TtydInstance.__post_init__ below. user_id=None is pre-seeded at slot 0,
# never reassigned, so the no-accounts case never depends on assignment
# order. threading.Lock (not RLock - nothing here re-enters it) guards the
# read-then-write race: two concurrent first-time requests for the same
# new user_id must not each hand out a different slot number.
_user_slots: dict[str | None, int] = {None: 0}
_next_user_slot = 1
_user_slot_lock = threading.Lock()

# tmux session name -> cwd we last put that session in (via -c at creation
# or a send-keys `cd` on a later reconnect - see ensure_session). Lets
# ensure_session tell "the candidate moved to a new question since this tab
# last connected" apart from "same question, just reconnecting/reloading" -
# only the former should ever poke a live shell with an unrequested `cd`.
_last_cwd_by_session: dict[str, str] = {}


def _user_slot(user_id: str | None) -> int:
    global _next_user_slot
    if user_id in _user_slots:
        return _user_slots[user_id]
    with _user_slot_lock:
        if user_id not in _user_slots:  # re-check inside the lock
            _user_slots[user_id] = _next_user_slot
            _next_user_slot += 1
        return _user_slots[user_id]


def _port_for(user_id: str | None, tab_id: int) -> int:
    return TTYD_BASE_PORT + _user_slot(user_id) * MAX_TERMINAL_TABS + (tab_id - 1)


def _tmux_session_name(user_id: str | None, tab_id: int) -> str:
    if user_id:
        return f"clusterdrill-{user_id}-{tab_id}"
    return f"clusterdrill-{tab_id}"

# Shared xterm.js client options (ttyd --client-option)
_CLIENT_OPTIONS = [
    "--client-option", "disableLeaveAlert=true",
    "--client-option", "fontFamily='IBM Plex Mono, monospace'",
    "--client-option", "fontSize=13",
    "--client-option", "cursorBlink=true",
    "--client-option", "scrollback=5000",
]


@dataclass
class TtydInstance:
    tab_id: int
    user_id: str | None = None
    # issue #122 (M7): which node this tab's shell runs on - None (or
    # "control-plane") is the existing, unchanged default (a bare shell on
    # the app's own host); any other value names a worker node this tab
    # reaches via `kubectl debug node/<name>` instead (see
    # _shell_command). Fixed for this tab's whole lifetime, same as
    # everything else in ttyd's argv - set once at first ensure_tab() call
    # for this (user_id, tab_id), never changed by a later call (a
    # reconnect/reload just reuses whatever this tab already is).
    node_target: str | None = None
    host: str = TTYD_HOST
    port: int = 0
    _proc: subprocess.Popen | None = field(default=None, repr=False)

    def __post_init__(self) -> None:
        if self.port == 0:
            self.port = _port_for(self.user_id, self.tab_id)

    @property
    def base_url(self) -> str:
        return f"http://{self.host}:{self.port}/"

    @property
    def tmux_session_name(self) -> str:
        return _tmux_session_name(self.user_id, self.tab_id)

    @property
    def is_running(self) -> bool:
        return self._proc is not None and self._proc.poll() is None

    def start(self, ttyd_bin: str, env: dict[str, str]) -> bool:
        if self.is_running:
            return True

        tmux_bin = shutil.which("tmux") if self.node_target and self.node_target != "control-plane" else None
        if tmux_bin:
            # tmux sessions outlive this process (an app restart/crash
            # leaves them running) but `_shell_command` only decides
            # control-plane-vs-debug-node once, right here, for a brand
            # new TtydInstance. Without this, `tmux new-session -A`
            # below would silently reattach to a same-named session left
            # over from this tab's *previous* life - reusing whatever it
            # was targeting then - instead of actually landing on the
            # node this instance now promises. Only done for the debug-
            # node path: the plain control-plane case relies on exactly
            # this same-session reattach to survive app restarts, and
            # that existing behavior must not regress.
            subprocess.run(
                [tmux_bin, "kill-session", "-t", self.tmux_session_name],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )

        cmd = [
            ttyd_bin,
            "--port", str(self.port),
            "--interface", self.host,
            "--writable",
            *_CLIENT_OPTIONS,
            *_shell_command(self.tab_id, self.user_id, self.node_target),
        ]
        logger.info(
            "starting ttyd tab %s (user=%s, node=%s): bound to %s:%s (tmux %s)",
            self.tab_id, self.user_id, self.node_target or "control-plane", self.host, self.port, self.tmux_session_name,
        )
        self._proc = subprocess.Popen(
            cmd,
            env=env,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )

        deadline = time.monotonic() + STARTUP_WAIT_SECONDS
        while time.monotonic() < deadline:
            if self._proc.poll() is not None:
                logger.warning(
                    "ttyd tab %s exited immediately (code %s)",
                    self.tab_id, self._proc.returncode,
                )
                self._proc = None
                return False
            time.sleep(STARTUP_POLL_INTERVAL)
        return True

    def stop(self) -> None:
        if self._proc is None:
            return
        if self._proc.poll() is None:
            logger.info("stopping ttyd tab %s (pid %s)", self.tab_id, self._proc.pid)
            self._proc.terminate()
            try:
                self._proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self._proc.kill()
                self._proc.wait(timeout=5)
        self._proc = None


class TtydPool:
    """One ttyd + tmux session per (user, terminal tab) - see this module's
    docstring for the per-user scoping this class implements."""

    def __init__(self, max_tabs: int = MAX_TERMINAL_TABS):
        self.max_tabs = max(1, max_tabs)
        self.host = TTYD_HOST
        self._tabs: dict[tuple[str | None, int], TtydInstance] = {}
        self._ttyd_bin: str | None = None

    @property
    def is_running(self) -> bool:
        tab1 = self._tabs.get((None, 1))
        return tab1 is not None and tab1.is_running

    def start(self) -> None:
        self._ttyd_bin = shutil.which("ttyd")
        if self._ttyd_bin is None:
            logger.warning(
                "ttyd binary not found on PATH - terminal panel unavailable. "
                "Install with `brew install ttyd`."
            )
            return
        # App-startup tab, before any request (and therefore any user_id)
        # exists yet - always the no-accounts slot (None).
        self.ensure_tab(1)

    def stop(self) -> None:
        for key in sorted(self._tabs.keys(), key=lambda k: (k[0] or "", k[1]), reverse=True):
            self._tabs[key].stop()
        self._tabs.clear()

    def ensure_tab(self, tab_id: int, user_id: str | None = None, node_target: str | None = None) -> TtydInstance | None:
        """Starts (user_id, tab_id)'s ttyd if it isn't already running.

        node_target only matters the first time this (user_id, tab_id) is
        ever created - a later call (a reconnect, or the tab already
        existing) ignores whatever node_target it's given and returns the
        existing instance unchanged, same as every other argv-fixed-at-
        Popen-time property already documented below.

        Does NOT touch the tmux session's starting directory - see
        ensure_session() for that. Kept separate on purpose: ttyd's own
        argv is fixed once at Popen() time and reused for every future
        client connection for as long as that process lives (confirmed by
        testing - its trailing shell command does not re-evaluate per
        connection), so baking a directory in here would only ever reflect
        whatever question happened to be active the first time this exact
        tab number's ttyd process was ever spawned - for tab 1 specifically,
        that's app startup, before any question has been viewed at all.
        ensure_session() is called fresh on every real terminal connection
        instead, so it always sees the actually-current question.
        """
        if tab_id < 1 or tab_id > self.max_tabs:
            return None
        if self._ttyd_bin is None:
            self._ttyd_bin = shutil.which("ttyd")
        if self._ttyd_bin is None:
            return None

        key = (user_id, tab_id)
        inst = self._tabs.get(key)
        if inst is None:
            inst = TtydInstance(tab_id=tab_id, user_id=user_id, node_target=node_target, host=self.host)
            self._tabs[key] = inst

        if not inst.is_running:
            if not inst.start(self._ttyd_bin, _spawn_env(user_id)):
                if key != (None, 1):
                    self._tabs.pop(key, None)
                return None
        return inst

    def base_url_for(self, tab_id: int, user_id: str | None = None, node_target: str | None = None) -> str | None:
        inst = self.ensure_tab(tab_id, user_id, node_target)
        return inst.base_url if inst else None

    def kill_all_tmux_sessions(self) -> None:
        """Kills every tab's tmux session outright, for every user_id ever
        seen this run - the actual cluster access, not just the ttyd
        process bridging to it. Called by app.py's idle watchdog (idle.py)
        once nobody's touched the keyboard for too long: stopping ttyd
        alone would not be enough, since ttyd's own tmux wrapper
        (_shell_command) recreates/reattaches a session on its next
        connection (`tmux new-session -A`) rather than requiring a dead one
        to be explicitly torn down. Iterates every possible tab_id up to
        max_tabs for every known user_id (not just self._tabs' currently-
        tracked instances), so a tab whose ttyd process this app never
        happened to spawn this run (e.g. after a restart) still gets its
        tmux session killed if one is lingering from before. Leaves ttyd
        itself running - harmless with no tmux session behind it, and it
        lazily creates a fresh one the next time someone actually
        reconnects after logging back in.

        Still global across every user: the
        idle watchdog tracks one shared activity clock (idle.py), not a
        per-user one, so it has no way to know *which* user has actually
        gone idle - a per-user idle clock is a follow-on refinement, not
        part of this phase.

        Also deletes any worker-node tab's debug pod (issue #122) for
        every known user_id, independent of whether tmux itself is even
        installed - killing (or never having a) local tmux session
        doesn't stop a debug pod, a separate Kubernetes object (see
        rbac.delete_debug_pod), so this always runs rather than being
        skipped when tmux_bin is None below.
        """
        for user_id in list(_user_slots.keys()):
            if user_id is None:
                continue  # no-accounts slot never has a debug pod to clean up
            for tab_id in range(1, self.max_tabs + 1):
                rbac.delete_debug_pod(user_id, tab_id)

        tmux_bin = shutil.which("tmux")
        if tmux_bin is None:
            return
        for user_id in list(_user_slots.keys()):
            for tab_id in range(1, self.max_tabs + 1):
                session_name = _tmux_session_name(user_id, tab_id)
                subprocess.run(
                    [tmux_bin, "kill-session", "-t", session_name],
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                )

    def kill_user_tmux_sessions(self, user_id: str) -> None:
        """Every tmux session (and tracked ttyd process) belonging to one
        user - used when an admin deletes their account
        (routers/admin_router.py), so a deleted account doesn't leave a
        still-live shell into the cluster with no owner behind it. Also
        deletes any worker-node tab's debug pod (issue #122) for the same
        reason - see kill_all_tmux_sessions' identical note on why a
        killed tmux session doesn't stop one on its own. (Also called
        independently by rbac.delete_user_service_account's own cleanup -
        harmless to run twice, kubectl delete --ignore-not-found is
        idempotent.)"""
        tmux_bin = shutil.which("tmux")
        for tab_id in range(1, self.max_tabs + 1):
            rbac.delete_debug_pod(user_id, tab_id)
            if tmux_bin is not None:
                session_name = _tmux_session_name(user_id, tab_id)
                subprocess.run(
                    [tmux_bin, "kill-session", "-t", session_name],
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                )
            inst = self._tabs.pop((user_id, tab_id), None)
            if inst is not None:
                inst.stop()


def _send_cd(tmux_bin: str, session_name: str, cwd: str) -> None:
    """Best-effort: moves an already-running tmux session to cwd without
    losing its scrollback - fixes a terminal-continuity bug where a
    candidate switching questions was left in the previous question's
    directory, with no visible sign the terminal hadn't followed them.
    `C-u` clears
    whatever's typed on the current input line first, so a half-typed
    command doesn't get silently submitted or mashed together with ours;
    if the pane is running a foreground program instead of sitting at a
    shell prompt, both keys land on that program instead, same as any
    send-keys automation - acceptable here since a question switch means
    whatever that program was doing is almost certainly no longer
    relevant. `clear` after the `cd` gives a clean screen at the new
    prompt without touching tmux's own scroll-history buffer, so the
    candidate can still scroll up to their prior work if they want it.
    """
    subprocess.run(
        [tmux_bin, "send-keys", "-t", session_name, "C-u"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    subprocess.run(
        [tmux_bin, "send-keys", "-t", session_name, f"cd {shlex.quote(cwd)} && clear", "Enter"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )


def ensure_session(inst: TtydInstance, cwd: str | None) -> None:
    """Creates inst's tmux session if it doesn't exist yet, starting it in
    cwd. Call this on every real terminal connection, not just when ttyd
    itself needed starting - cheap (`tmux has-session` is near-instant) and
    it's the only way a tab whose tmux session died independently (e.g. the
    candidate typed `exit`) picks up the *current* question's directory on
    its next reattach instead of whatever was current when that tab was
    first ever used.

    If the session is already running AND cwd names a question this
    session hasn't already been moved to, it's actively steered there with
    a `cd` (see _send_cd) rather than left wherever it was - the earlier
    behavior (cwd silently ignored once a session existed) left an open tab
    showing a stale question's directory and history with nothing on
    screen to say so. Reconnecting to the *same* question (a page reload,
    a second tab open on it) is a no-op - _last_cwd_by_session is what
    tells those two cases apart, so simply revisiting a question you're
    already in doesn't repeatedly clear your screen underneath you.
    """
    tmux_bin = shutil.which("tmux")
    if tmux_bin is None:
        return

    # Ensure a server+session exists BEFORE touching any `-g` (server-wide)
    # option below: `tmux set-option -g` is a no-op (exit 1, "no server
    # running") when no tmux server exists yet at all (a true cold start -
    # first connection since boot, or right after this app/server was
    # restarted and the old tmux server died with it) - a bare
    # `start-server` doesn't reliably keep it alive either, since a server
    # with no sessions can exit again immediately. Only creating the actual
    # session first guarantees the server stays up long enough for the
    # `set-option` calls further down to actually stick.
    exists = subprocess.run(
        [tmux_bin, "has-session", "-t", inst.tmux_session_name],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    ).returncode == 0
    if not exists:
        cmd = [tmux_bin, "new-session", "-d", "-s", inst.tmux_session_name]
        if cwd:
            cmd += ["-c", cwd]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if cwd:
            _last_cwd_by_session[inst.tmux_session_name] = cwd
    elif cwd and _last_cwd_by_session.get(inst.tmux_session_name) != cwd:
        _send_cd(tmux_bin, inst.tmux_session_name, cwd)
        _last_cwd_by_session[inst.tmux_session_name] = cwd

    # tmux always draws through the terminal's alternate screen buffer (how
    # it renders panes/status-bar at all), which makes xterm.js's own
    # "Alternate Scroll Mode" kick in for every mouse-wheel tick - that mode
    # exists so mouse-less full-screen pagers can still be scrolled, and it
    # works by translating each wheel tick into a repeated Up/Down arrow
    # keypress sent straight to whatever's running in the pane. At a bare
    # bash prompt, readline reads that as "cycle through command history" -
    # exactly the "scrolling changes my command" bug this fixes. Turning on
    # tmux's own `mouse` option makes tmux consume wheel events itself
    # (scroll the pane's history / enter copy-mode) instead of leaving them
    # to fall through to that arrow-key emulation. This is a *server*-wide
    # tmux option, not a per-session one - `-g` here reaches whichever tmux
    # server this call's session lives on, new or already-running, since a
    # long-lived server never re-reads a config file after it first starts
    # (a `-f` flag on some future `new-session` call would be silently
    # ignored). Cheap and idempotent, so it's set on every call rather than
    # only the first - simpler than tracking "have I already done this for
    # this server" separately.
    subprocess.run(
        [tmux_bin, "set-option", "-g", "mouse", "on"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )

    # tmux's own scroll history (`history-limit`) is a separate buffer from
    # xterm.js's `scrollback` client option (_CLIENT_OPTIONS above, set to
    # 5000) - every keystroke/output byte passes through tmux's pane buffer
    # first, so tmux silently drops lines off the back of ITS ring before
    # xterm.js ever sees them. tmux's compiled-in default is only 2000
    # lines (each wrapped visual row counts as one line too), so a single
    # long `-o yaml` dump could push earlier output - or even its own top -
    # out of range well before xterm's 5000-line window fills up, and
    # scrolling up just stops with no way to reach content that's already
    # gone. Matching xterm's value here (same `-g`/idempotent reasoning as
    # `mouse on` above) closes that gap.
    subprocess.run(
        [tmux_bin, "set-option", "-g", "history-limit", "5000"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )


# issue #122 (M7): the image a worker-node tab's debug pod runs - same
# choice, and same chroot-into-the-host-filesystem approach, as the
# existing q107-13-debug-node-shell question's own reference answer
# (questions/observability/q107-13-debug-node-shell/ANSWER.md), for
# consistency with the one piece of this bank that already does this.
NODE_DEBUG_IMAGE = "busybox:1.36"


def _debug_node_shell_command(node_target: str, user_id: str, tab_id: int) -> list[str]:
    """`kubectl debug node/<node_target>`, run as this tab's tmux pane
    command instead of a bare shell - reuses an already-running debug pod
    on a reconnect (checked via `kubectl get pod` first) instead of trying
    to create a second one under the same name, which `kubectl debug`
    would otherwise reject outright. The pod's deterministic name
    (rbac.debug_pod_name) is also what the resourceNames-scoped Role
    rbac.ensure_user_service_account grants this user is restricted to -
    see that module for the actual isolation boundary; this function only
    ever runs inside that user's own restricted-kubeconfig ttyd process
    (_spawn_env), never with the app's own admin credentials.
    """
    pod_name = rbac.debug_pod_name(user_id, tab_id)
    script = (
        f"kubectl get pod {shlex.quote(pod_name)} -n {shlex.quote(SYSTEM_NAMESPACE)} >/dev/null 2>&1 "
        f"&& exec kubectl exec -it {shlex.quote(pod_name)} -n {shlex.quote(SYSTEM_NAMESPACE)} -- chroot /host sh "
        f"|| exec kubectl debug node/{shlex.quote(node_target)} -it --image={NODE_DEBUG_IMAGE} "
        f"-n {shlex.quote(SYSTEM_NAMESPACE)} --name={shlex.quote(pod_name)} -- chroot /host sh"
    )
    return ["sh", "-c", script]


def _shell_command(tab_id: int, user_id: str | None = None, node_target: str | None = None) -> list[str]:
    tmux_bin = shutil.which("tmux")
    session = _tmux_session_name(user_id, tab_id)
    if tmux_bin is None:
        if tab_id == 1 and user_id is None:
            logger.warning("tmux not found - terminal will not persist across page reloads.")
        return [TTYD_FALLBACK_SHELL]
    # A worker-node tab needs a real, logged-in identity behind it - its
    # debug pod's RBAC scoping (rbac.ensure_user_service_account) is keyed
    # on user_id, and there is no "anonymous worker debug" concept. The
    # password-gate-off / no-accounts mode (user_id=None) simply never
    # offers a worker option in the UI (routers/terminal_router.py's node-
    # list endpoint), so this is a defensive fallback, not a real path.
    if node_target and node_target != "control-plane" and user_id:
        return [tmux_bin, "new-session", "-A", "-s", session, *_debug_node_shell_command(node_target, user_id, tab_id)]
    return [tmux_bin, "new-session", "-A", "-s", session]


def _spawn_env(user_id: str | None = None) -> dict[str, str]:
    """user_id=None (no accounts) gets the
    app's own inherited environment unchanged - the exact prior behavior,
    same trust boundary as local dev/SSH-tunnel access generally. A real
    user_id gets KUBECONFIG pointed at that user's own restricted
    ServiceAccount kubeconfig (rbac.py) instead - the actual mechanism that
    stops their terminal from reaching another user's namespace. Defensive
    ensure_user_service_account() call here (idempotent) covers an account
    created before this feature existed, or a kubeconfig file lost to e.g.
    a disk wipe - rbac.py's own docstring covers the normal provisioning
    path (account creation, app startup)."""
    env = dict(os.environ)
    if users.single_user_mode():
        return env
    if not user_id:
        return env
    kubeconfig_path = rbac.user_kubeconfig_path(user_id)
    if not kubeconfig_path.exists():
        rbac.ensure_user_service_account(user_id)
    if kubeconfig_path.exists():
        env["KUBECONFIG"] = str(kubeconfig_path)
    else:
        logger.warning(
            "no RBAC-scoped kubeconfig available for user %s - falling back "
            "to the app's own (unrestricted) kubeconfig for this terminal",
            user_id,
        )
    return env


# Backward-compatible singleton used by app.py
manager = TtydPool()
