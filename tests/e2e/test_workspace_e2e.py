"""Browser regressions using the real template/assets and a disposable HTTP fixture.

No cluster, authentication, or ttyd process is started here.
Terminal responses are stubs: shell continuity and xterm sizing need appliance tests.
Run with the dependencies in tests/e2e/requirements.txt:
    pytest tests/e2e/test_workspace_e2e.py
"""
from __future__ import annotations

import functools
import threading
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import pytest
from jinja2 import Environment, FileSystemLoader

ROOT = Path(__file__).resolve().parents[2]


@pytest.fixture(scope="module")
def workspace_url(tmp_path_factory):
    root = tmp_path_factory.mktemp("workspace-browser")
    (root / "static").symlink_to(ROOT / "web/static", target_is_directory=True)
    env = Environment(loader=FileSystemLoader(ROOT / "web/templates"), autoescape=True)
    for name, exam, terminal in [("index", False, True), ("exam", True, True), ("unavailable", False, False), ("retry", True, True)]:
        html = env.get_template("question.html").render(
            question={"id": "q100-a-long-question-identifier-for-workspace-testing", "topic": "workloads"},
            profile_snapshot={}, terminal_available=terminal, terminal_url="/terminal/t/1/",
            terminal_max_tabs=5, task_html="<h2>Configure the workload</h2><p>Complete the task.</p><pre>"
            + "kubectl get pods " * 40 + "</pre>",
            tab="task", position=1, total=2, progress_pct=50, in_active_session=True,
            combo=0, can_reset=True, next_id="next", prev_id="previous", is_exam_session=exam,
            session_mode="exam" if exam else "fixed", timer_enabled=exam, timer_deadline=time.time() + 3600,
            advance_ready=exam,
            provision_error="cluster unreachable" if name == "retry" else None,
        )
        (root / f"{name}.html").write_text(html)
    handler = functools.partial(SimpleHTTPRequestHandler, directory=str(root))
    server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    yield f"http://127.0.0.1:{server.server_port}"
    server.shutdown()
    server.server_close()
    thread.join()


@pytest.fixture
def workspace_page(page):
    # Keep third-party fonts/CDN scripts and backend calls out of this fixture.
    page.route("https://**/*", lambda route: route.abort())
    page.route("**/terminal/**", lambda route: route.fulfill(body="<html><body><input aria-label='Shell'></body></html>", content_type="text/html"))
    page.route("**/idle-status", lambda route: route.fulfill(json={"enabled": False}))
    return page


def assert_fits(page):
    size = page.evaluate("({viewport: innerWidth, document: document.documentElement.scrollWidth})")
    print(size)
    assert size["document"] <= size["viewport"]


def test_resize_shrink_hide_and_reload(workspace_page, workspace_url):
    page = workspace_page
    page.set_viewport_size({"width": 1440, "height": 900})
    page.goto(workspace_url)
    for axis, arrow in [("0", "ArrowRight"), ("1", "ArrowUp")]:
        handle = page.locator(f'[data-resize-index="{axis}"]')
        handle.focus()
        page.keyboard.press(arrow)
    for width in [1280, 1100, 1024, 900, 820, 768, 1440]:
        page.set_viewport_size({"width": width, "height": 900})
        assert_fits(page)
    page.locator("#terminal-toggle").click()
    question = page.locator("#question-panel").bounding_box()
    layout = page.locator(".layout").bounding_box()
    assert question["width"] >= layout["width"] - 41
    assert not page.locator("#terminal-panel").is_visible()
    page.reload()
    assert page.locator("#terminal-toggle").inner_text() == "Show terminal"
    assert page.locator("#terminal-frame-1").get_attribute("src") is None
    page.goto(f"{workspace_url}/exam.html")
    assert not page.locator("#terminal-panel").is_visible()
    assert page.locator("#end-session-btn").inner_text() == "Submit Exam"


@pytest.mark.parametrize("width,height", [(1440, 900), (1280, 800), (820, 1180), (768, 1024), (1024, 768), (1180, 820), (390, 844), (320, 700), (1200, 500)])
def test_viewport_geometry(workspace_page, workspace_url, width, height):
    page = workspace_page
    page.set_viewport_size({"width": width, "height": height})
    page.goto(f"{workspace_url}/exam.html")
    assert_fits(page)
    page.locator("#terminal-toggle").click()
    assert_fits(page)
    assert page.locator("#end-session-btn").is_visible()
    if width <= 699:
        prev = page.locator(".question-nav-prev").bounding_box()
        nxt = page.locator(".question-nav-next").bounding_box()
        submit = page.locator("#end-session-btn").bounding_box()
        assert abs(prev["y"] - nxt["y"]) <= 2
        assert nxt["x"] >= prev["x"] + prev["width"] - 1
        assert submit["y"] >= prev["y"] + prev["height"] - 1


def test_lazy_connection_and_retained_frame(workspace_page, workspace_url):
    page = workspace_page
    page.add_init_script('localStorage.setItem("clusterdrill-workspace-v2", JSON.stringify({version:2, terminalVisible:false}))')
    requests = []
    page.on("request", lambda request: requests.append(request.url) if "/terminal/" in request.url else None)
    page.goto(workspace_url)
    assert requests == []
    page.locator("#terminal-toggle").click()
    shell = page.frame_locator("#terminal-frame-1").get_by_label("Shell")
    shell.fill("unfinished command")
    page.evaluate('document.getElementById("terminal-toggle").click()')
    assert page.locator("#terminal-toggle").evaluate("el => el === document.activeElement")
    page.locator("#terminal-toggle").click()
    assert shell.input_value() == "unfinished command"
    assert len(requests) == 1


@pytest.mark.parametrize("stored", ['[833,13,554]', '[null,13,500]', '[-1,13,500]', '["800",13,500]', '{broken'])
def test_legacy_migration(workspace_page, workspace_url, stored):
    page = workspace_page
    page.add_init_script(f'if (window === window.top) localStorage.setItem("clusterdrill-layout-columns", {stored!r})')
    page.set_viewport_size({"width": 1100, "height": 800})
    page.goto(workspace_url)
    assert_fits(page)
    value = page.evaluate('JSON.parse(localStorage.getItem("clusterdrill-workspace-v2"))')
    expected = 833 / (833 + 554) if stored == '[833,13,554]' else 0.58
    assert value["questionFraction"] == pytest.approx(expected)
    assert page.evaluate('localStorage.getItem("clusterdrill-layout-columns")') is None


def test_storage_unavailable_and_reset(workspace_page, workspace_url):
    page = workspace_page
    page.add_init_script('Object.defineProperty(window, "localStorage", {get() { throw new Error("blocked"); }})')
    page.goto(workspace_url)
    page.locator('[data-resize-index="0"]').focus()
    page.keyboard.press("ArrowRight")
    page.locator("#terminal-toggle").click()
    page.locator("#layout-reset").click()
    assert not page.locator("#terminal-panel").is_visible()
    assert page.evaluate("window.clusterdrillWorkspace.get().questionFraction") == 0.58
    assert_fits(page)


def test_pointer_drag_cleanup_and_compact_checklist(workspace_page, workspace_url):
    page = workspace_page
    page.set_viewport_size({"width": 1440, "height": 900})
    page.goto(workspace_url)
    box = page.locator('[data-resize-index="0"]').bounding_box()
    page.mouse.move(box["x"] + 6, box["y"] + 40)
    page.mouse.down()
    page.mouse.move(box["x"] + 86, box["y"] + 40)
    page.mouse.up()
    assert page.evaluate("window.clusterdrillWorkspace.get().questionFraction") > 0.58
    assert page.locator(".checklist-panel").evaluate("el => getComputedStyle(el).maxHeight") == "none"
    assert not page.locator("body").evaluate('el => el.classList.contains("workspace-resizing")')
    page.set_viewport_size({"width": 390, "height": 844})
    page.locator("#criteria-list").evaluate('el => el.innerHTML = "<li>A populated grading result</li>".repeat(40)')
    checklist = page.locator(".checklist-panel").bounding_box()
    terminal = page.locator("#terminal-panel").bounding_box()
    assert terminal["y"] >= checklist["y"] + checklist["height"]
    assert page.locator(".workspace-jump").count() == 0
    assert_fits(page)


@pytest.mark.parametrize("stored", ['null', '{broken', '{"version":2,"questionFraction":2,"taskFraction":-1,"terminalVisible":"false"}'])
def test_invalid_preferences(workspace_page, workspace_url, stored):
    page = workspace_page
    page.add_init_script(f'if (window === window.top) localStorage.setItem("clusterdrill-workspace-v2", {stored!r})')
    page.goto(workspace_url)
    assert page.locator("#terminal-panel").is_visible()
    assert page.evaluate("window.clusterdrillWorkspace.get().questionFraction") == 0.58
    assert_fits(page)


def test_terminal_unavailable(workspace_page, workspace_url):
    page = workspace_page
    page.goto(f"{workspace_url}/unavailable.html")
    assert page.locator("#terminal-toggle").count() == 0
    assert page.locator("iframe").count() == 0
    assert page.locator("#check-btn").is_visible()
    assert_fits(page)


def test_enlarged_text(workspace_page, workspace_url):
    page = workspace_page
    page.set_viewport_size({"width": 320, "height": 700})
    page.goto(workspace_url)
    page.evaluate("""() => {
      const sizes = [...document.querySelectorAll('body *')].map(el => [el, parseFloat(getComputedStyle(el).fontSize)]);
      sizes.forEach(([el, size]) => { el.style.fontSize = `${size * 2}px`; });
    }""")
    assert_fits(page)
    assert page.locator("#end-session-btn").is_visible()



def test_exam_single_row_and_submission(workspace_page, workspace_url):
    page = workspace_page
    page.add_init_script('if (window === window.top) localStorage.setItem("clusterdrill-workspace-v2", JSON.stringify({version:2, taskFraction:0.2}))')
    page.set_viewport_size({"width": 1440, "height": 900})
    page.goto(f"{workspace_url}/exam.html")
    assert page.locator(".checklist-panel").count() == 0
    assert page.locator('[data-resize-index="1"]').count() == 0
    assert page.locator('.tab-panel').count() == 1
    task = page.locator("#question-panel").bounding_box()
    terminal = page.locator("#terminal-panel").bounding_box()
    assert task["height"] == pytest.approx(terminal["height"], abs=1)
    assert page.locator("#timer-value").inner_text() != "--:--"
    page.locator("#terminal-toggle").click()
    assert page.locator("#question-panel").bounding_box()["height"] == pytest.approx(task["height"], abs=1)
    page.route("**/sessions/submit*", lambda route: route.fulfill(json={"ok": True}))
    page.route("**/sessions/results", lambda route: route.fulfill(body="Exam results", content_type="text/html"))
    with page.expect_request("**/sessions/submit*") as request:
        page.locator("#end-session-btn").click()
    assert request.value.method == "POST"
    page.wait_for_url("**/sessions/results")


def test_exam_setup_recovery_without_checklist(workspace_page, workspace_url):
    page = workspace_page
    page.set_viewport_size({"width": 320, "height": 700})
    page.goto(f"{workspace_url}/retry.html")
    assert page.locator(".checklist-panel").count() == 0
    assert page.locator("#provision-error #reset-btn").is_visible()
    assert_fits(page)
    page.route("**/questions/*/reset", lambda route: route.fulfill(status=500, json={"detail": "Try again"}))
    page.locator("#reset-btn").click()
    page.wait_for_function('document.getElementById("provision-status").textContent.includes("Try again")')
    assert page.locator("#reset-btn").is_enabled()
    page.route("**/questions/*/reset", lambda route: route.fulfill(json={"ok": True}))
    page.locator("#reset-btn").click()
    page.wait_for_function('document.getElementById("provision-status").textContent.includes("Setup complete")')
    assert page.locator("#reset-btn").count() == 0
    assert page.locator("#provision-status").evaluate("el => el === document.activeElement")
    assert page.locator("#end-session-btn").is_visible()
    assert_fits(page)
