"""ttyd_manager.py: naming/argv-shape logic only, subprocess/shutil.which
always mocked - see tests/conftest.py's autouse safety-net fixture for why
this is a hard requirement, not a convention, after this session's real
tmux-session-loss incident. Never lets a real `tmux`/`ttyd` binary run.

_user_slots/_next_user_slot are module-
level (see ttyd_manager.py's own docstring for why) - reset around every
test here so one test assigning a slot to "alice" can't change another
test's expected port/session-name math or kill_all_tmux_sessions() sweep,
same reasoning as test_auth.py's _reset_auth_module_globals fixture.
"""
from __future__ import annotations

from unittest.mock import MagicMock

import pytest
import ttyd_manager


@pytest.fixture(autouse=True)
def _reset_user_slots():
    ttyd_manager._user_slots.clear()
    ttyd_manager._user_slots[None] = 0
    ttyd_manager._next_user_slot = 1
    yield
    ttyd_manager._user_slots.clear()
    ttyd_manager._user_slots[None] = 0
    ttyd_manager._next_user_slot = 1


def test_ttyd_instance_default_port_offset_by_tab_id():
    inst1 = ttyd_manager.TtydInstance(tab_id=1)
    inst3 = ttyd_manager.TtydInstance(tab_id=3)
    assert inst1.port == ttyd_manager.TTYD_BASE_PORT
    assert inst3.port == ttyd_manager.TTYD_BASE_PORT + 2


def test_ttyd_instance_tmux_session_name():
    inst = ttyd_manager.TtydInstance(tab_id=2)
    assert inst.tmux_session_name == "clusterdrill-2"


def test_ttyd_instance_port_scoped_per_user():
    # First-seen user gets slot 1 (slot 0 is reserved for user_id=None) -
    # its port block starts MAX_TERMINAL_TABS ports after the no-accounts
    # block, not overlapping it.
    inst = ttyd_manager.TtydInstance(tab_id=1, user_id="alice")
    assert inst.port == ttyd_manager.TTYD_BASE_PORT + ttyd_manager.MAX_TERMINAL_TABS


def test_ttyd_instance_tmux_session_name_scoped_per_user():
    inst = ttyd_manager.TtydInstance(tab_id=2, user_id="alice")
    assert inst.tmux_session_name == "clusterdrill-alice-2"


def test_two_users_get_non_overlapping_port_blocks():
    alice_tab1 = ttyd_manager.TtydInstance(tab_id=1, user_id="alice")
    bob_tab1 = ttyd_manager.TtydInstance(tab_id=1, user_id="bob")
    assert alice_tab1.port != bob_tab1.port
    assert alice_tab1.tmux_session_name != bob_tab1.tmux_session_name


def test_same_user_id_always_gets_the_same_slot():
    first = ttyd_manager.TtydInstance(tab_id=1, user_id="alice")
    second = ttyd_manager.TtydInstance(tab_id=1, user_id="alice")
    assert first.port == second.port


def test_ttyd_instance_base_url():
    inst = ttyd_manager.TtydInstance(tab_id=1, host="127.0.0.1", port=7681)
    assert inst.base_url == "http://127.0.0.1:7681/"


def test_pool_ensure_tab_rejects_out_of_bounds(monkeypatch):
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: "/usr/bin/ttyd")
    pool = ttyd_manager.TtydPool(max_tabs=3)
    assert pool.ensure_tab(0) is None
    assert pool.ensure_tab(4) is None


def test_shell_command_uses_tmux_new_session_when_available(monkeypatch):
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: f"/usr/bin/{name}")
    cmd = ttyd_manager._shell_command(2)
    assert cmd == ["/usr/bin/tmux", "new-session", "-A", "-s", "clusterdrill-2"]


def test_shell_command_falls_back_to_bare_shell_without_tmux(monkeypatch):
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: None)
    cmd = ttyd_manager._shell_command(1)
    assert cmd == [ttyd_manager.TTYD_FALLBACK_SHELL]


# --- node_target (issue #122 / M7) ---------------------------------------

def test_shell_command_control_plane_target_is_byte_for_byte_unchanged(monkeypatch):
    # None and the literal "control-plane" must both reproduce today's
    # exact argv - this is the "existing behavior is unchanged" guarantee
    # the ticket's acceptance criteria calls for.
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: f"/usr/bin/{name}")
    plain = ttyd_manager._shell_command(2, "alice")
    assert ttyd_manager._shell_command(2, "alice", None) == plain
    assert ttyd_manager._shell_command(2, "alice", "control-plane") == plain


def test_shell_command_worker_target_wraps_kubectl_debug_node(monkeypatch):
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: f"/usr/bin/{name}")
    cmd = ttyd_manager._shell_command(3, "alice", "worker-1")
    assert cmd[:5] == ["/usr/bin/tmux", "new-session", "-A", "-s", "clusterdrill-alice-3"]
    assert cmd[5:7] == ["sh", "-c"]
    script = cmd[7]
    assert "kubectl debug node/worker-1" in script
    assert "--image=busybox:1.36" in script
    assert "chroot /host sh" in script
    # The debug pod's name is deterministic per (user_id, tab_id) - see
    # rbac.debug_pod_name - both to survive a reconnect and because it's
    # exactly what the resourceNames-scoped Role restricts this user to.
    assert ttyd_manager.rbac.debug_pod_name("alice", 3) in script


def test_shell_command_worker_target_reuses_an_existing_pod_via_exec(monkeypatch):
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: f"/usr/bin/{name}")
    script = ttyd_manager._shell_command(1, "alice", "worker-1")[7]
    # The reconnect path (pod already exists) must exec into it, never
    # attempt a second `kubectl debug` under the same name - kubectl
    # rejects creating a pod that already exists outright.
    assert "kubectl get pod" in script
    assert "kubectl exec -it" in script
    assert " || " in script  # falls through to `kubectl debug` only on the get failing


def test_shell_command_ignores_worker_target_without_a_user_id(monkeypatch):
    # No-accounts mode (user_id=None) has no per-user RBAC/debug-pod
    # identity to scope a worker session to - question_view's own
    # worker_nodes context is already empty in that mode, but this is the
    # server-side backstop in case a node= query param reaches here anyway.
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: f"/usr/bin/{name}")
    cmd = ttyd_manager._shell_command(1, None, "worker-1")
    assert cmd == ["/usr/bin/tmux", "new-session", "-A", "-s", "clusterdrill-1"]


# --- start() vs. a stale same-named tmux session from a prior process life ---
# (issue #122: a live incident hit during this ticket's own manual browser
# testing - an app restart left an old tmux session alive under this tab's
# exact name; `tmux new-session -A` then silently reattached to it instead
# of running the freshly-requested debug-node command.)

def test_start_kills_any_stale_same_named_session_before_a_worker_target(monkeypatch):
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: f"/usr/bin/{name}")
    monkeypatch.setattr(ttyd_manager, "STARTUP_WAIT_SECONDS", 0)
    manager = MagicMock()
    manager.popen.return_value.poll.return_value = None  # still running past STARTUP_WAIT_SECONDS
    monkeypatch.setattr(ttyd_manager.subprocess, "Popen", manager.popen)
    monkeypatch.setattr(ttyd_manager.subprocess, "run", manager.run)

    inst = ttyd_manager.TtydInstance(tab_id=2, user_id="alice", node_target="worker-1")
    assert inst.start("/usr/bin/ttyd", {}) is True

    manager.run.assert_called_once_with(
        ["/usr/bin/tmux", "kill-session", "-t", "clusterdrill-alice-2"],
        stdout=ttyd_manager.subprocess.DEVNULL, stderr=ttyd_manager.subprocess.DEVNULL,
    )
    # The kill must happen before Popen spawns ttyd, not after - a stale
    # session has to be gone *before* ttyd's own `tmux new-session -A` runs.
    assert [c[0] for c in manager.mock_calls] == ["run", "popen"]


def test_start_leaves_a_control_plane_targets_session_alone(monkeypatch):
    # The plain control-plane path deliberately relies on the opposite
    # behavior (surviving an app restart via the same-named session) -
    # this must not regress into always killing first.
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: f"/usr/bin/{name}")
    monkeypatch.setattr(ttyd_manager, "STARTUP_WAIT_SECONDS", 0)
    mock_popen = MagicMock()
    mock_popen.return_value.poll.return_value = None
    monkeypatch.setattr(ttyd_manager.subprocess, "Popen", mock_popen)
    mock_run = MagicMock()
    monkeypatch.setattr(ttyd_manager.subprocess, "run", mock_run)

    inst = ttyd_manager.TtydInstance(tab_id=2, user_id="alice")
    assert inst.start("/usr/bin/ttyd", {}) is True

    mock_run.assert_not_called()


def test_start_worker_target_without_tmux_binary_never_calls_run(monkeypatch):
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: None)
    monkeypatch.setattr(ttyd_manager, "STARTUP_WAIT_SECONDS", 0)
    mock_popen = MagicMock()
    mock_popen.return_value.poll.return_value = None
    monkeypatch.setattr(ttyd_manager.subprocess, "Popen", mock_popen)
    mock_run = MagicMock()
    monkeypatch.setattr(ttyd_manager.subprocess, "run", mock_run)

    inst = ttyd_manager.TtydInstance(tab_id=1, user_id="alice", node_target="worker-1")
    assert inst.start("/usr/bin/ttyd", {}) is True

    mock_run.assert_not_called()


def test_kill_all_tmux_sessions_calls_kill_session_per_tab(monkeypatch):
    """The exact function responsible for this session's real incident
    (killed two live tmux sessions during a non-pytest manual test) -
    verified here purely against a mock, argv shape only, real tmux never
    touched. subprocess.run is replaced with a MagicMock for this test only
    (shadows conftest's autouse guard, which is fine - a MagicMock never
    shells out regardless)."""
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: "/usr/bin/tmux")
    mock_run = MagicMock()
    monkeypatch.setattr(ttyd_manager.subprocess, "run", mock_run)

    pool = ttyd_manager.TtydPool(max_tabs=3)
    pool.kill_all_tmux_sessions()

    assert mock_run.call_count == 3
    called_session_names = [call.args[0][3] for call in mock_run.call_args_list]
    assert called_session_names == ["clusterdrill-1", "clusterdrill-2", "clusterdrill-3"]
    for call in mock_run.call_args_list:
        argv = call.args[0]
        assert argv[:3] == ["/usr/bin/tmux", "kill-session", "-t"]


def test_kill_all_tmux_sessions_noop_without_tmux_binary(monkeypatch):
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: None)
    mock_run = MagicMock()
    monkeypatch.setattr(ttyd_manager.subprocess, "run", mock_run)

    pool = ttyd_manager.TtydPool(max_tabs=3)
    pool.kill_all_tmux_sessions()

    mock_run.assert_not_called()


def test_kill_all_tmux_sessions_sweeps_every_known_user(monkeypatch):
    # A user's slot gets assigned the moment any of their tabs is touched
    # (ensure_tab/TtydInstance construction) - kill_all_tmux_sessions must
    # then sweep that user's tab range too, not just the no-accounts one.
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: "/usr/bin/tmux")
    mock_run = MagicMock()
    monkeypatch.setattr(ttyd_manager.subprocess, "run", mock_run)
    # issue #122: also deletes each known user's worker-node debug pods
    # (rbac.delete_debug_pod) - a separate concern from this test's own
    # (tmux session name sweep), mocked out here rather than asserted on.
    monkeypatch.setattr(ttyd_manager.rbac, "delete_debug_pod", MagicMock())

    ttyd_manager.TtydInstance(tab_id=1, user_id="alice")  # assigns alice a slot

    pool = ttyd_manager.TtydPool(max_tabs=2)
    pool.kill_all_tmux_sessions()

    called_session_names = {call.args[0][3] for call in mock_run.call_args_list}
    assert called_session_names == {
        "clusterdrill-1", "clusterdrill-2",
        "clusterdrill-alice-1", "clusterdrill-alice-2",
    }


def test_kill_all_tmux_sessions_deletes_debug_pods_for_every_known_user_but_not_none(monkeypatch):
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: "/usr/bin/tmux")
    monkeypatch.setattr(ttyd_manager.subprocess, "run", MagicMock())
    mock_delete = MagicMock()
    monkeypatch.setattr(ttyd_manager.rbac, "delete_debug_pod", mock_delete)

    ttyd_manager.TtydInstance(tab_id=1, user_id="alice")  # assigns alice a slot

    pool = ttyd_manager.TtydPool(max_tabs=2)
    pool.kill_all_tmux_sessions()

    mock_delete.assert_any_call("alice", 1)
    mock_delete.assert_any_call("alice", 2)
    # The no-accounts slot (user_id=None) never has a debug pod - rbac's
    # naming/RBAC scheme is keyed on a real user_id string throughout.
    assert all(call.args[0] is not None for call in mock_delete.call_args_list)


def test_ensure_tab_keys_instances_per_user(monkeypatch):
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: "/usr/bin/ttyd")
    monkeypatch.setattr(ttyd_manager.TtydInstance, "start", lambda self, *a, **kw: True)
    monkeypatch.setattr(ttyd_manager.TtydInstance, "is_running", property(lambda self: True))

    pool = ttyd_manager.TtydPool(max_tabs=2)
    alice_inst = pool.ensure_tab(1, "alice")
    bob_inst = pool.ensure_tab(1, "bob")

    assert alice_inst is not bob_inst
    assert alice_inst.port != bob_inst.port
    # Same (user, tab) pair returns the same instance, not a fresh one.
    assert pool.ensure_tab(1, "alice") is alice_inst


def test_ensure_tab_same_user_can_open_multiple_control_plane_tabs(monkeypatch):
    # issue #122's acceptance criteria explicitly calls for verifying this
    # rather than assuming it - one user opening a second (or third) plain
    # control-plane tab must get an independent instance, not the tab-1
    # instance reused or a collision.
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: "/usr/bin/ttyd")
    monkeypatch.setattr(ttyd_manager.TtydInstance, "start", lambda self, *a, **kw: True)
    monkeypatch.setattr(ttyd_manager.TtydInstance, "is_running", property(lambda self: True))

    pool = ttyd_manager.TtydPool(max_tabs=3)
    tab1 = pool.ensure_tab(1, "alice")
    tab2 = pool.ensure_tab(2, "alice")
    tab3 = pool.ensure_tab(3, "alice")

    assert len({tab1.port, tab2.port, tab3.port}) == 3
    assert len({tab1.tmux_session_name, tab2.tmux_session_name, tab3.tmux_session_name}) == 3
    assert all(t.node_target is None for t in (tab1, tab2, tab3))


def test_ensure_tab_sets_node_target_only_on_first_creation(monkeypatch):
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: "/usr/bin/ttyd")
    monkeypatch.setattr(ttyd_manager.TtydInstance, "start", lambda self, *a, **kw: True)
    monkeypatch.setattr(ttyd_manager.TtydInstance, "is_running", property(lambda self: True))

    pool = ttyd_manager.TtydPool(max_tabs=2)
    first = pool.ensure_tab(2, "alice", "worker-1")
    assert first.node_target == "worker-1"

    # A later call for the same (user, tab) - a reconnect/reload - must
    # return the existing instance untouched, ignoring whatever
    # node_target it's given (ttyd's own argv is already fixed by now).
    again = pool.ensure_tab(2, "alice", "control-plane")
    assert again is first
    assert again.node_target == "worker-1"


def test_kill_user_tmux_sessions_only_targets_that_user(monkeypatch):
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: "/usr/bin/tmux")
    mock_run = MagicMock()
    monkeypatch.setattr(ttyd_manager.subprocess, "run", mock_run)
    monkeypatch.setattr(ttyd_manager.rbac, "delete_debug_pod", MagicMock())

    pool = ttyd_manager.TtydPool(max_tabs=2)
    pool.kill_user_tmux_sessions("alice")

    called_session_names = [call.args[0][3] for call in mock_run.call_args_list]
    assert called_session_names == ["clusterdrill-alice-1", "clusterdrill-alice-2"]


def test_kill_user_tmux_sessions_deletes_each_tabs_debug_pod(monkeypatch):
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: "/usr/bin/tmux")
    monkeypatch.setattr(ttyd_manager.subprocess, "run", MagicMock())
    mock_delete = MagicMock()
    monkeypatch.setattr(ttyd_manager.rbac, "delete_debug_pod", mock_delete)

    pool = ttyd_manager.TtydPool(max_tabs=2)
    pool.kill_user_tmux_sessions("alice")

    mock_delete.assert_any_call("alice", 1)
    mock_delete.assert_any_call("alice", 2)
    assert mock_delete.call_count == 2


# --- _spawn_env ------------------------------

def test_spawn_env_no_accounts_is_unmodified_inherited_env(monkeypatch):
    monkeypatch.setattr(ttyd_manager.os, "environ", {"PATH": "/usr/bin", "HOME": "/home/x"})
    env = ttyd_manager._spawn_env(None)
    assert env == {"PATH": "/usr/bin", "HOME": "/home/x"}
    assert "KUBECONFIG" not in env


def test_spawn_env_single_user_mode_never_provisions_user_rbac(monkeypatch):
    monkeypatch.setenv("CLUSTERDRILL_SINGLE_USER", "true")
    ensure = MagicMock()
    monkeypatch.setattr(ttyd_manager.rbac, "ensure_user_service_account", ensure)

    env = ttyd_manager._spawn_env("admin")

    assert env["CLUSTERDRILL_SINGLE_USER"] == "true"
    ensure.assert_not_called()


def test_spawn_env_real_user_points_kubeconfig_at_their_own_file(monkeypatch, tmp_path):
    kubeconfig = tmp_path / "alice.yaml"
    kubeconfig.write_text("fake kubeconfig")
    monkeypatch.setattr(ttyd_manager.rbac, "user_kubeconfig_path", lambda user_id: kubeconfig)
    monkeypatch.setattr(ttyd_manager.rbac, "ensure_user_service_account", MagicMock())

    env = ttyd_manager._spawn_env("alice")

    assert env["KUBECONFIG"] == str(kubeconfig)
    ttyd_manager.rbac.ensure_user_service_account.assert_not_called()  # already existed


def test_spawn_env_provisions_missing_kubeconfig_on_demand(monkeypatch, tmp_path):
    kubeconfig = tmp_path / "alice.yaml"  # does not exist yet
    monkeypatch.setattr(ttyd_manager.rbac, "user_kubeconfig_path", lambda user_id: kubeconfig)

    def fake_ensure(user_id):
        kubeconfig.write_text("provisioned")
        return True

    monkeypatch.setattr(ttyd_manager.rbac, "ensure_user_service_account", fake_ensure)

    env = ttyd_manager._spawn_env("alice")
    assert env["KUBECONFIG"] == str(kubeconfig)


def test_spawn_env_falls_back_to_admin_env_when_provisioning_fails(monkeypatch, tmp_path):
    kubeconfig = tmp_path / "alice.yaml"  # never gets created
    monkeypatch.setattr(ttyd_manager.rbac, "user_kubeconfig_path", lambda user_id: kubeconfig)
    monkeypatch.setattr(ttyd_manager.rbac, "ensure_user_service_account", lambda user_id: False)

    env = ttyd_manager._spawn_env("alice")
    assert "KUBECONFIG" not in env


# --- ensure_session (terminal-continuity fix) --------------------------------
# A candidate switching questions used to leave every already-open terminal
# tab silently sitting in the previous question's directory (cwd was only
# ever applied to a genuinely new tmux session) - these pin the fix: an
# existing session gets actively `cd`'d when the question actually changed,
# and left alone on a same-question reconnect so it doesn't stomp on
# whatever the candidate is mid-typing every time they reload the page.

@pytest.fixture(autouse=True)
def _reset_last_cwd_by_session():
    ttyd_manager._last_cwd_by_session.clear()
    yield
    ttyd_manager._last_cwd_by_session.clear()


def _mock_run_has_session(exists: bool):
    def fake_run(argv, **kwargs):
        result = MagicMock()
        if argv[1] == "has-session":
            result.returncode = 0 if exists else 1
        else:
            result.returncode = 0
        return result
    return fake_run


def test_ensure_session_creates_new_session_with_cwd(monkeypatch):
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: "/usr/bin/tmux")
    mock_run = MagicMock(side_effect=_mock_run_has_session(exists=False))
    monkeypatch.setattr(ttyd_manager.subprocess, "run", mock_run)

    inst = ttyd_manager.TtydInstance(tab_id=1)
    ttyd_manager.ensure_session(inst, cwd="/work/q104-01")

    new_session_calls = [c for c in mock_run.call_args_list if c.args[0][1] == "new-session"]
    assert len(new_session_calls) == 1
    assert new_session_calls[0].args[0][-2:] == ["-c", "/work/q104-01"]
    assert ttyd_manager._last_cwd_by_session[inst.tmux_session_name] == "/work/q104-01"


def test_ensure_session_cds_existing_session_on_question_change(monkeypatch):
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: "/usr/bin/tmux")
    mock_run = MagicMock(side_effect=_mock_run_has_session(exists=True))
    monkeypatch.setattr(ttyd_manager.subprocess, "run", mock_run)

    inst = ttyd_manager.TtydInstance(tab_id=1)
    ttyd_manager._last_cwd_by_session[inst.tmux_session_name] = "/work/q104-01"

    ttyd_manager.ensure_session(inst, cwd="/work/q104-02")

    send_keys_calls = [c.args[0] for c in mock_run.call_args_list if c.args[0][1] == "send-keys"]
    assert any(argv[4] == "C-u" for argv in send_keys_calls)
    assert any("/work/q104-02" in argv[4] for argv in send_keys_calls if len(argv) > 4)
    assert ttyd_manager._last_cwd_by_session[inst.tmux_session_name] == "/work/q104-02"


def test_ensure_session_reconnect_to_same_question_does_not_cd(monkeypatch):
    monkeypatch.setattr(ttyd_manager.shutil, "which", lambda name: "/usr/bin/tmux")
    mock_run = MagicMock(side_effect=_mock_run_has_session(exists=True))
    monkeypatch.setattr(ttyd_manager.subprocess, "run", mock_run)

    inst = ttyd_manager.TtydInstance(tab_id=1)
    ttyd_manager._last_cwd_by_session[inst.tmux_session_name] = "/work/q104-01"

    ttyd_manager.ensure_session(inst, cwd="/work/q104-01")

    send_keys_calls = [c for c in mock_run.call_args_list if c.args[0][1] == "send-keys"]
    assert send_keys_calls == []
