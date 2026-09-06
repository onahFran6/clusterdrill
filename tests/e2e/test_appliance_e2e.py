"""Browser-level E2E coverage for the local Minikube appliance.

Every test here drives a real Chromium browser (Playwright) against a
real, disposable `clusterdrill` Minikube profile provisioned by
conftest.py's fixtures - this reproduces the actual learner/operator path
(a real login form post with a real CSRF token, a real terminal WebSocket,
a real `check.sh` subprocess run against live cluster state) rather than
calling routes directly the way web/tests' httpx-based route tests do.

Test order matters and is deliberate: the password-gated tests must run
before the --no-password ones (see conftest.py's appliance_url_no_password
docstring - it re-installs the same running profile in --no-password
mode). pytest's default file-declaration collection order is what
enforces that, so keep the password-gated tests above the no-password
ones in this file.

Run with (after `pip install -r requirements.txt && playwright install
chromium` in this directory):
    python -m pytest -q
"""
from __future__ import annotations

import json
import subprocess
import time

from conftest import E2E_PASSWORD
from playwright.sync_api import expect

QUESTION_ID = "q101-01-create-pod-imperative"
TERMINAL_FRAME_TITLE = "Embedded terminal 1 (ttyd)"

# grading_client.py's CLUSTERDRILL_NAMESPACE_SUFFIX ("-{user_id}") applies whenever
# a real account is logged in - the
# bootstrap admin account's user_id slugifies to exactly "admin" on a fresh
# install (users._unique_user_id only appends "-2" etc on a slug collision,
# and a freshly provisioned cluster has no other user to collide with), so
# the namespace setup.sh actually creates for the password-gated flow's
# admin session is suffixed, not the bare question id.
ADMIN_NAMESPACE_SUFFIX = "-admin"
SOLVE_NAMESPACE = f"{QUESTION_ID}{ADMIN_NAMESPACE_SUFFIX}"
SOLVE_COMMAND = f"kubectl run web-scratch --image=nginx:1.25-alpine -n {SOLVE_NAMESPACE}"


def _kubectl(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["kubectl", "--context", "clusterdrill", *args],
        text=True, capture_output=True, check=True,
    )


def _wait_for_pod(namespace: str, name: str, *, timeout_s: float = 15.0) -> None:
    """Poll live cluster state for a pod the terminal's typed command should
    have created - see test_full_learner_path... for why this, not a
    rendered-terminal-text assertion, is what actually proves the typed
    command executed."""
    deadline = time.monotonic() + timeout_s
    while time.monotonic() < deadline:
        result = _kubectl("get", "pod", name, "-n", namespace, "--ignore-not-found", "-o", "name")
        if result.stdout.strip():
            return
        time.sleep(1)
    raise AssertionError(f"pod/{name} was never created in namespace {namespace} within {timeout_s}s")


def _login(page, base_url: str, password: str) -> None:
    page.goto(f"{base_url}/topics")
    assert "/login" in page.url, f"expected a redirect to /login, landed on {page.url}"
    page.locator("#username").fill("admin")
    page.locator("#password").fill(password)
    page.get_by_role("button", name="Log in").click()


# --- password-gated flow (must run before the --no-password tests below) --

def test_password_gate_rejects_wrong_password(page, appliance_url_password_gated):
    _login(page, appliance_url_password_gated, "definitely-the-wrong-password")
    expect(page.get_by_text("Wrong username or password.")).to_be_visible()
    assert "/login" in page.url


def test_password_gate_accepts_correct_password_and_reaches_topics(page, appliance_url_password_gated):
    _login(page, appliance_url_password_gated, E2E_PASSWORD)
    expect(page).to_have_url(f"{appliance_url_password_gated}/topics")
    expect(page.get_by_role("heading", name="Cross-topic mixed session")).to_be_visible()


def test_ttyd_has_no_service_or_nodeport_of_its_own(appliance_url_password_gated):
    """Invariant: the embedded terminal must never be
    directly reachable, only proxied through the app's own password-gated
    routes (routers/terminal_router.py) - so the manifest must define
    exactly one Service in the appliance namespace (the web app's), never
    a second one for ttyd."""
    result = _kubectl("get", "svc", "-n", "clusterdrill-system", "-o", "json")
    services = json.loads(result.stdout)["items"]
    assert len(services) == 1, f"expected exactly one Service, found: {[s['metadata']['name'] for s in services]}"
    assert services[0]["metadata"]["name"] == "clusterdrill"
    assert services[0]["spec"]["type"] == "ClusterIP"


def test_full_learner_path_start_session_solve_check_reset(page, appliance_url_password_gated):
    """Topics -> start a Fixed session -> question route -> type a real
    kubectl command into the embedded terminal -> Check grades live
    cluster state -> Reset clears it again. This is the real learner path,
    with no direct pod/kubectl execution from the test
    itself substitutes for any of these steps."""
    _login(page, appliance_url_password_gated, E2E_PASSWORD)
    expect(page.get_by_role("heading", name="Cross-topic mixed session")).to_be_visible()

    # Session start: the imperative-commands topic's row "Fixed" button -
    # a real form POST with the page's own CSRF token, not a direct GET.
    topic_row = page.locator(".kget-row", has=page.get_by_role("link", name="imperative-commands"))
    topic_row.get_by_role("button", name="Fixed").click()

    # Question route: Fixed always starts with q101-01 first (deterministic
    # order - see sessions.py's start_fixed).
    expect(page).to_have_url(f"{appliance_url_password_gated}/questions/{QUESTION_ID}")
    expect(page.locator("#check-btn")).to_be_visible()

    # Terminal WebSocket: type a real kubectl command into the embedded
    # terminal and confirm it actually reached the cluster. ttyd's xterm
    # instance renders to a <canvas>, not real DOM text nodes (confirmed
    # live: the accessibility tree exposes the terminal iframe as a single
    # leaf with no text children), so asserting on rendered terminal
    # output isn't possible from Playwright - checking the real resource
    # the command should have created is what actually proves the
    # terminal is a live shell into the cluster, not a static mock,
    # reachable only through the app's own proxy.
    # A genuinely fresh terminal tab spawns a brand-new tmux session and
    # ttyd child process server-side (routers/terminal_router.py's proxy,
    # ttyd_manager.py) - that cold start is measurably slower than the
    # WebSocket reconnecting to an already-running session, so give it a
    # generous wait before the first keystrokes. Between retries, send
    # Ctrl+C first to cancel any partial line a too-early attempt may have
    # left half-typed, so a retry never appends onto stray leftover input.
    terminal = page.frame_locator(f'iframe[title="{TERMINAL_FRAME_TITLE}"]')
    page.wait_for_timeout(5_000)
    for attempt in range(3):
        terminal.locator("body").click()
        if attempt > 0:
            page.keyboard.press("Control+C")
            page.keyboard.press("Enter")
            page.wait_for_timeout(500)
        page.keyboard.type(SOLVE_COMMAND)
        page.keyboard.press("Enter")
        try:
            _wait_for_pod(SOLVE_NAMESPACE, "web-scratch", timeout_s=10.0)
            break
        except AssertionError:
            if attempt == 2:
                raise

    # Check: grades the live cluster state the terminal command just
    # created, via a real check.sh subprocess run server-side.
    page.locator("#check-btn").click()
    expect(page.get_by_text("check complete")).to_be_visible(timeout=20_000)
    expect(page.get_by_text("SCORE: 3/3")).to_be_visible()

    # Reset: clears the checklist back to its unsolved placeholder.
    page.locator("#reset-btn").click()
    expect(page.get_by_text("click Check to grade your work")).to_be_visible(timeout=20_000)


# --- --no-password flow (must run after the password-gated tests above) ---

def test_no_password_flow_reaches_topics_without_login(page, appliance_url_no_password):
    page.goto(f"{appliance_url_no_password}/topics")
    expect(page).to_have_url(f"{appliance_url_no_password}/topics")
    expect(page.get_by_role("heading", name="Cross-topic mixed session")).to_be_visible()
