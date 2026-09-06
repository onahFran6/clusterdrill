// "Terminal Ops" v1/v2 redesigns. No SPA framework, no build step -
// everything below is plain DOM/fetch. This file is now
// loaded on both the question/practice page and the hub pages (progress.html,
// for the skill radar) - each block below guards on its own elements'
// presence so it's a no-op on pages that don't have them, rather than
// assuming every element always exists.

// CSRF: read once from the <meta name="csrf-token"> tag every template that
// loads this file renders (see _shell.html/question.html) and sent as a
// header on every mutating fetch() call below - see auth.py's CSRF section
// for the server-side half. Empty string pre-login/gate-off, matching
// require_csrf_form()'s own no-op behavior in those cases.
const CSRF_TOKEN = document.querySelector('meta[name="csrf-token"]')?.content || "";
function csrfHeaders(extra) {
  return { "X-CSRF-Token": CSRF_TOKEN, ...extra };
}

// The one shared themed confirmation dialog (#confirm-dialog, rendered by
// _macros.html's confirm_dialog() - every template that loads this file
// calls it once, same convention as CSRF_TOKEN above). Resolves true only
// if the visitor clicked the dialog's own "confirm" button; Cancel,
// Escape, and a backdrop click all resolve false via the native <dialog>
// close event, no extra wiring needed for any of those three paths.
function confirmAction(message, confirmLabel) {
  return new Promise((resolve) => {
    const dialog = document.getElementById("confirm-dialog");
    if (!dialog) {
      resolve(false);
      return;
    }
    document.getElementById("confirm-dialog-message").textContent = message;
    document.getElementById("confirm-dialog-confirm-btn").textContent = confirmLabel;
    dialog.showModal();
    dialog.addEventListener(
      "close",
      () => resolve(dialog.returnValue === "confirm"),
      { once: true },
    );
  });
}

// Any form can opt into a themed confirmation before it actually submits -
// add data-confirm="<message>" (and optionally data-confirm-label, default
// "Confirm") rather than wiring up a one-off listener per destructive
// action. Delete user (admin.html) is the first user of this; the same
// mechanism the mid-session "leave and end it?" prompt below uses.
document.querySelectorAll("form[data-confirm]").forEach((form) => {
  form.addEventListener("submit", async (event) => {
    if (form.dataset.confirmed === "true") return;
    event.preventDefault();
    const ok = await confirmAction(form.dataset.confirm, form.dataset.confirmLabel || "Confirm");
    if (ok) {
      form.dataset.confirmed = "true";
      form.requestSubmit();
    }
  });
});

(function () {
  const body = document.body;
  const qid = body.dataset.questionId;
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  // Mermaid init, moved here from an inline <script> in
  // question.html (2026-08 CSP hardening pass - script-src can't allow
  // 'unsafe-inline' once a real CSP is on, so this had to become part of
  // this externally-loaded file instead). `startOnLoad: false` + an
  // explicit run() call (see renderMermaidIfNeeded() below) rather than the
  // default auto-run-on-DOMContentLoaded, because the Diagram tab's markup
  // is present in the DOM on every page load (all four tabs render
  // server-side, CSS just hides the inactive ones) - auto-start would try
  // to render even when the Task tab is the one actually shown. "dark"
  // theme matches this app's existing dark color scheme (style.css's
  // --ink/--panel/--text palette).
  if (window.mermaid) {
    mermaid.initialize({ startOnLoad: false, theme: "dark", securityLevel: "loose" });
  }

  const checkBtn = document.getElementById("check-btn");
  // .question-view is on <body> for every question page render (see
  // question.html) - unlike checkBtn, it's present even during an exam
  // session, which renders no Check button/checklist at all (deferred
  // grading means no live feedback). Everything in this block used
  // to be gated on checkBtn directly, which meant an exam question would
  // silently skip terminal-tab and timer-countdown setup too, both also
  // in this block - those must keep working on every question page
  // regardless of whether the grading UI is present.
  const isQuestionPage = document.body.classList.contains("question-view");

  // Everything in this block is question/practice-page-only - progress.html
  // and the other hub pages load this same script file just for the
  // radar-chart block further down, and don't have any of these elements.
  if (isQuestionPage) {
    const resetBtn = document.getElementById("reset-btn");
    const statusEl = document.getElementById("check-status");
    const listEl = document.getElementById("criteria-list");
    const scoreEl = document.getElementById("score-line");

    // check-status is the shared .alert component in .alert-compact mode
    // (style.css) - kind maps onto the same variant vocabulary the
    // alert() macro uses elsewhere (pending -> warning, done -> success,
    // error -> critical), so this element's class list matches what the
    // macro would render for the same state, even though this one is set
    // directly rather than through a template re-render.
    const STATUS_KIND_TO_VARIANT = { pending: "warning", done: "success", error: "critical" };
    function setStatus(text, kind) {
      // Absent during an exam session (no Check button, no checklist
      // panel at all) - runReset() still calls this, since
      // Reset itself stays available in exam mode.
      if (!statusEl) return;
      statusEl.textContent = text;
      const variant = STATUS_KIND_TO_VARIANT[kind];
      statusEl.className = "alert alert-compact" + (variant ? " alert-" + variant : " alert-idle");
    }

    // Signature element: bracket-style [ ]/[✓]/[✗] rows, monospace, reading
    // like CI/test-runner output rather than a generic checkbox list - this
    // IS the product's actual value (live, per-criterion feedback against a
    // real cluster), so it gets the most deliberate visual treatment in the
    // app. Each row gets a small staggered reveal (CSS `.criterion` handles
    // the animation itself; this only sets animation-delay per index) -
    // skipped entirely under prefers-reduced-motion.
    function renderCriteria(criteria) {
      if (!listEl) return;
      listEl.innerHTML = "";
      if (!criteria || criteria.length === 0) {
        const li = document.createElement("li");
        li.className = "criteria-empty";
        li.textContent = "no criteria reported";
        listEl.appendChild(li);
        return;
      }
      criteria.forEach((c, i) => {
        const li = document.createElement("li");
        li.className = "criterion " + (c.passed ? "criterion-pass" : "criterion-fail");
        if (!reducedMotion) {
          li.style.animationDelay = `${i * 40}ms`;
        } else {
          li.style.animation = "none";
          li.style.opacity = "1";
        }
        const mark = document.createElement("span");
        mark.className = "criterion-mark";
        mark.textContent = c.passed ? "[✓]" : "[✗]";
        const desc = document.createElement("span");
        desc.className = "criterion-desc";
        desc.textContent = c.description;
        li.appendChild(mark);
        li.appendChild(desc);
        listEl.appendChild(li);
      });
    }

    // --- Elapsed-time + hint-used tracking for this attempt ---
    // "This attempt" spans multiple real page loads (Skip/Previous, a
    // browser refresh) - Task/Hint/Solution/Diagram switches are
    // client-side only now (see #content-tabs below) and don't reload at
    // all, but Reset/Skip/Previous/refresh still do, so a plain in-memory
    // timestamp still can't survive those. localStorage, keyed per-qid,
    // does. Both keys are cleared on Reset (a fresh attempt) and never
    // touched by grading itself - purely informational, same invariant as
    // everywhere else.
    const ATTEMPT_START_KEY = `clusterdrill-attempt-start-${qid}`;
    const ATTEMPT_HINT_KEY = `clusterdrill-attempt-usedhint-${qid}`;

    function attemptStartMs() {
      let start = localStorage.getItem(ATTEMPT_START_KEY);
      if (!start) {
        start = String(Date.now());
        try { localStorage.setItem(ATTEMPT_START_KEY, start); } catch { /* private browsing, etc. */ }
      }
      return parseFloat(start);
    }

    function markUsedHint() {
      try { localStorage.setItem(ATTEMPT_HINT_KEY, "1"); } catch { /* ignore */ }
    }

    function usedHintThisAttempt() {
      return localStorage.getItem(ATTEMPT_HINT_KEY) === "1";
    }

    function clearAttemptState() {
      try {
        localStorage.removeItem(ATTEMPT_START_KEY);
        localStorage.removeItem(ATTEMPT_HINT_KEY);
      } catch { /* ignore */ }
    }

    if (body.dataset.tab === "hint" || body.dataset.tab === "solution") {
      markUsedHint();
    }

    // --- Content tabs: Task/Hint/Solution/Diagram, client-side only -------
    // Used to be a plain <a href> nav - a full page reload on every click,
    // which reconnected the terminal iframe's ttyd websocket from scratch
    // and wiped the just-run grading checklist (pure client-side state).
    // All four panels already render server-side into the DOM (see
    // question.html); this just toggles which is visible, same pattern as
    // the terminal sub-tabs below. pushState keeps the URL (and Back/
    // Forward) working like a real navigation without one.
    const contentTabsEl = document.getElementById("content-tabs");
    if (contentTabsEl) {
      const tabPanels = document.querySelectorAll(".tab-panel");
      let mermaidRendered = false;

      function renderMermaidIfNeeded() {
        if (mermaidRendered || !window.mermaid) return;
        const diagramEl = document.querySelector('.tab-panel[data-tab-panel="diagram"] .mermaid');
        if (!diagramEl) return;
        mermaidRendered = true;
        mermaid.run({ nodes: [diagramEl] });
      }

      function activateContentTab(targetTab) {
        contentTabsEl.querySelectorAll(".tab").forEach((t) => {
          t.classList.toggle("active", t.dataset.tab === targetTab);
        });
        tabPanels.forEach((p) => {
          p.classList.toggle("active", p.dataset.tabPanel === targetTab);
        });
        body.dataset.tab = targetTab;
        if (targetTab === "diagram") {
          renderMermaidIfNeeded();
        }
      }

      if (body.dataset.tab === "diagram") {
        renderMermaidIfNeeded();
      }

      contentTabsEl.addEventListener("click", (event) => {
        const link = event.target.closest(".tab");
        if (!link) return;
        event.preventDefault();
        if (link.classList.contains("active")) return;
        const targetTab = link.dataset.tab;
        if (targetTab === "hint" || targetTab === "solution") {
          markUsedHint();
        }
        activateContentTab(targetTab);
        history.pushState({ tab: targetTab }, "", link.href);
      });

      window.addEventListener("popstate", () => {
        const params = new URLSearchParams(window.location.search);
        activateContentTab(params.get("tab") || "task");
      });
    }

    // --- Solution tab: Discovery Path/Exact Solution toggle -----------------
    // Only present when app.py found sequence data to generate a Discovery
    // Path from (question.html's {% if discovery_path_html %} branch) - a
    // question with no diagram.json sequence just shows Exact Solution
    // directly with no toggle at all, same optional-block guard pattern as
    // everything else here.
    const solutionSubtabsEl = document.getElementById("solution-subtabs");
    if (solutionSubtabsEl) {
      const solutionPanels = document.querySelectorAll(".solution-subtab-panel");
      solutionSubtabsEl.addEventListener("click", (event) => {
        const btn = event.target.closest(".solution-subtab");
        if (!btn) return;
        const target = btn.dataset.solutionSubtab;
        solutionSubtabsEl.querySelectorAll(".solution-subtab").forEach((b) => {
          b.classList.toggle("active", b.dataset.solutionSubtab === target);
        });
        solutionPanels.forEach((p) => {
          p.classList.toggle("active", p.dataset.solutionSubtabPanel === target);
        });
      });
    }

    // --- Diagram tab rebuild: Architecture/Sequence sub-tabs ---------------
    // Only present when app.py's question_context() found a diagram.json for
    // this item (question.html's {% if diagram_arch %} branch) - a question
    // still on the Mermaid fallback path has no #diagram-subtabs element at
    // all, so this whole block is a no-op there, same guard-on-presence
    // pattern as every other optional block in this file.
    const diagramSubtabsEl = document.getElementById("diagram-subtabs");
    if (diagramSubtabsEl && window.ClusterDrillDiagram) {
      const subPanels = document.querySelectorAll(".diagram-subtab-panel");
      const rendered = { arch: false, seq: false };

      function parseDiagramData(elId) {
        const dataEl = document.getElementById(elId);
        if (!dataEl || !dataEl.textContent) return null;
        try {
          return JSON.parse(dataEl.textContent);
        } catch {
          return null;
        }
      }

      function renderSubtabIfNeeded(sub) {
        if (rendered[sub]) return;
        const mount = document.getElementById(`diagram-${sub}-mount`);
        if (!mount) return;
        rendered[sub] = true;
        if (sub === "arch") {
          window.ClusterDrillDiagram.renderArchitecture(mount, parseDiagramData("diagram-arch-data"));
        } else {
          window.ClusterDrillDiagram.renderSequence(mount, parseDiagramData("diagram-seq-data"));
        }
      }

      function activateSubtab(sub) {
        diagramSubtabsEl.querySelectorAll(".tab").forEach((t) => {
          t.classList.toggle("active", t.dataset.subtab === sub);
        });
        subPanels.forEach((p) => {
          p.classList.toggle("active", p.dataset.subtabPanel === sub);
        });
        renderSubtabIfNeeded(sub);
      }

      diagramSubtabsEl.addEventListener("click", (event) => {
        const link = event.target.closest(".tab");
        if (!link) return;
        event.preventDefault();
        activateSubtab(link.dataset.subtab);
      });

      // Architecture is the default sub-tab (server-rendered "active" in
      // question.html) - render it as soon as the Diagram content-tab is
      // itself visible, same "render once shown" gate the Mermaid fallback
      // already uses, rather than unconditionally at page load when the
      // container could still be display:none (Diagram tab not the initial
      // one) and therefore have zero layout width to draw an SVG into.
      if (body.dataset.tab === "diagram") {
        renderSubtabIfNeeded("arch");
      }
      if (contentTabsEl) {
        contentTabsEl.addEventListener("click", (event) => {
          const link = event.target.closest('.tab[data-tab="diagram"]');
          if (link) renderSubtabIfNeeded("arch");
        });
      }
    }

    async function runCheck() {
      checkBtn.disabled = true;
      setStatus("checking your work...", "pending");
      scoreEl.textContent = "";
      try {
        const elapsedMs = Math.round(Date.now() - attemptStartMs());
        const usedHint = usedHintThisAttempt();
        const res = await fetch(`/questions/${encodeURIComponent(qid)}/check`, {
          method: "POST",
          headers: csrfHeaders({ "Content-Type": "application/json" }),
          body: JSON.stringify({ elapsed_ms: elapsedMs, used_hint: usedHint }),
        });
        const data = await res.json();
        if (!res.ok) {
          setStatus(`error: ${data.detail || res.statusText}`, "error");
          return;
        }
        renderCriteria(data.criteria);
        if (data.ok) {
          const tierSuffix = data.speed_tier
            ? ` - ${data.speed_tier[0].toUpperCase()}${data.speed_tier.slice(1)}!`
            : "";
          const bossSuffix = data.boss_won ? " - BOSS DEFEATED!" : "";
          setStatus(`check complete${tierSuffix}${bossSuffix}`, "done");
          scoreEl.textContent = `SCORE: ${data.passed}/${data.total}`;
          if (data.passed === data.total) {
            clearAttemptState();
          }
          updateProgressBadges(data);
          updateNavigatorStatus(data.passed === data.total);
          // HP hitting zero ends the fight immediately, mirroring
          // the timer's own auto-end-on-expiry below - "before HP or the
          // clock runs out" (the ticket's wording) treats both the same
          // way as a hard stop, not something you keep playing past.
          if (data.boss_hp === 0) {
            setStatus(`check complete${tierSuffix} - boss HP depleted, fight over`, "done");
            setTimeout(() => endSession("hp-zero"), 2000);
          }
        } else {
          setStatus(`warning: ${data.error || "unexpected grading output"}`, "error");
        }
      } catch (err) {
        setStatus(`request failed: ${err}`, "error");
      } finally {
        checkBtn.disabled = false;
      }
    }

    // Live-update the PB-time and combo badges in the topbar
    // after a Check, without a full reload - same "update in place from the
    // fetch response" pattern the checklist/score already use. Neither
    // badge exists in the DOM yet on a first-ever pass (question.html only
    // renders them server-side when profile_snapshot/combo are already
    // non-zero at page load), so this creates them on demand rather than
    // only updating an element that may not exist - otherwise the very
    // Check that earns your first PB wouldn't show it until the next
    // navigation.
    const topbarBadgesEl = document.querySelector(".topbar-badges");

    // Question navigator: the current item's own
    // status square would otherwise stay stuck on "visited" (its server-
    // rendered state at page load) until the next full page navigation -
    // every other live-updated badge above already updates in place from
    // the /check response, so this one should too.
    function updateNavigatorStatus(passed) {
      const current = document.querySelector(".question-navigator-item.current");
      if (!current) return;
      current.classList.remove("status-unvisited", "status-visited", "status-passed", "status-failed");
      current.classList.add(passed ? "status-passed" : "status-failed");
    }

    function ensureBadge(id, extraClass) {
      let el = document.getElementById(id);
      if (el || !topbarBadgesEl) return el;
      const wrapper = document.createElement("div");
      wrapper.className = "topic-badge" + (extraClass ? " " + extraClass : "");
      const span = document.createElement("span");
      span.id = id;
      wrapper.appendChild(span);
      topbarBadgesEl.appendChild(wrapper);
      return span;
    }

    function updateProgressBadges(data) {
      if (typeof data.profile_best_time_ms === "number") {
        const el = ensureBadge("pb-time-value");
        if (el) el.textContent = `PB: ${(data.profile_best_time_ms / 1000).toFixed(1)}s`;
      }
      if (typeof data.profile_best_speed_tier === "string" && data.profile_best_speed_tier) {
        const el = ensureBadge("speed-tier-value");
        if (el) {
          const tier = data.profile_best_speed_tier;
          el.textContent = tier[0].toUpperCase() + tier.slice(1);
        }
      }
      if (typeof data.boss_hp === "number" && typeof data.boss_max_hp === "number") {
        const fill = document.getElementById("boss-hp-fill");
        const label = document.getElementById("boss-hp-label");
        const pct = Math.max(0, Math.min(100, Math.round((data.boss_hp / data.boss_max_hp) * 100)));
        if (fill) {
          fill.style.width = pct + "%";
          fill.classList.toggle("boss-hp-low", data.boss_hp <= data.boss_max_hp * 0.3);
        }
        if (label) label.textContent = `Boss HP: ${data.boss_hp}/${data.boss_max_hp}`;
      }
      if (typeof data.combo === "number" && data.combo > 0) {
        const el = ensureBadge("combo-value");
        if (el) {
          el.textContent = `combo: ${data.combo}`;
          el.parentElement.style.color = "var(--signature)";
          el.parentElement.style.borderColor = "var(--signature)";
        }
      }
    }

    async function runReset() {
      if (!resetBtn) return;
      resetBtn.disabled = true;
      if (checkBtn) checkBtn.disabled = true;
      setStatus("resetting your environment (this can take a few seconds)...", "pending");
      if (listEl) {
        listEl.innerHTML = '<li class="criteria-empty">[&nbsp;] click <strong>Check</strong> to grade your work</li>';
      }
      if (scoreEl) scoreEl.textContent = "";
      try {
        const res = await fetch(`/questions/${encodeURIComponent(qid)}/reset`, { method: "POST", headers: csrfHeaders() });
        const data = await res.json();
        if (!res.ok) {
          setStatus(`reset failed: ${data.detail || res.statusText}`, "error");
          return;
        }
        clearAttemptState();
        setStatus("reset complete: namespace and resources rebuilt from scratch", "done");
      } catch (err) {
        setStatus(`request failed: ${err}`, "error");
      } finally {
        resetBtn.disabled = false;
        if (checkBtn) checkBtn.disabled = false;
      }
    }

    // checkBtn is absent entirely during an exam session - no
    // listener to attach means runCheck can never be invoked client-side,
    // satisfying "must not be called client-side at all in that mode"
    // outright rather than merely hiding a still-wired button.
    if (checkBtn) {
      checkBtn.addEventListener("click", runCheck);
    }
    if (resetBtn) {
      resetBtn.addEventListener("click", runReset);
    }

    // Terminal panel toggle. Visible by default (a real grid item, see
    // style.css's .layout.has-terminal) - this only exists for someone who
    // wants the space back. Collapsing/expanding flips one class on
    // .layout; style.css's .layout.terminal-collapsed rule handles both
    // hiding the panel and giving its column back to the left column.
    const terminalToggle = document.getElementById("terminal-toggle");
    const layoutEl = document.querySelector(".layout");
    const terminalPanel = document.getElementById("terminal-panel");

    // ttyd's own xterm.js registers a `beforeunload` "Leave site?" handler
    // once its websocket connects - real behavior for a plain browser tab
    // full of unsaved form text, but wrong here, and it silently blocked
    // *every* in-app navigation (tab switches, Skip/Previous, End session)
    // once a terminal connected. The fix lives in ttyd_manager.py:
    // `--client-option disableLeaveAlert=true` is ttyd's own documented
    // option for turning this off at the source.

    if (terminalToggle && layoutEl && terminalPanel) {
      terminalToggle.addEventListener("click", () => {
        const collapsed = layoutEl.classList.toggle("terminal-collapsed");
        const expanded = !collapsed;
        terminalToggle.setAttribute("aria-expanded", String(expanded));
        terminalPanel.setAttribute("aria-hidden", String(collapsed));
        terminalToggle.textContent = expanded ? "Hide terminal" : "Show terminal";
      });
    }

    // KodeKloud-style terminal tabs — each tab is an independent shell
    // (separate ttyd port + tmux session on the server). Hidden iframes stay
    // mounted so switching tabs does not kill running processes.
    const terminalTabsEl = document.getElementById("terminal-tabs");
    const terminalFramesEl = document.getElementById("terminal-frames");
    const terminalTabAdd = document.getElementById("terminal-tab-add");

    if (terminalTabsEl && terminalFramesEl && terminalTabAdd) {
      const maxTabs = parseInt(terminalTabsEl.dataset.maxTabs || "5", 10);
      const terminalNodePicker = document.getElementById("terminal-node-picker");
      let tabCount = 1;

      function activateTerminalTab(tabId) {
        terminalTabsEl.querySelectorAll(".terminal-tab").forEach((btn) => {
          const active = btn.dataset.tab === String(tabId);
          btn.classList.toggle("active", active);
          btn.setAttribute("aria-selected", String(active));
        });
        terminalFramesEl.querySelectorAll(".terminal-frame").forEach((frame) => {
          const active = frame.dataset.tab === String(tabId);
          frame.classList.toggle("active", active);
        });
      }

      // issue #122 (M7): nodeTarget is only ever consulted the first time
      // a given tabId's frame is created (matching the server side -
      // ttyd_manager.ensure_tab only honors node_target on a brand-new
      // tab) - a later call for a tab that already exists just returns
      // the existing iframe untouched, so re-activating an existing tab
      // never needs to know or re-pass its node target.
      function ensureTerminalFrame(tabId, nodeTarget) {
        let frame = document.getElementById(`terminal-frame-${tabId}`);
        if (frame) {
          return frame;
        }
        frame = document.createElement("iframe");
        frame.id = `terminal-frame-${tabId}`;
        frame.className = "terminal-frame";
        frame.dataset.tab = String(tabId);
        frame.src = nodeTarget && nodeTarget !== "control-plane"
          ? `/terminal/t/${tabId}/?node=${encodeURIComponent(nodeTarget)}`
          : `/terminal/t/${tabId}/`;
        frame.title = `Embedded terminal ${tabId} (ttyd)`;
        frame.setAttribute("allow", "clipboard-read; clipboard-write");
        terminalFramesEl.appendChild(frame);
        return frame;
      }

      terminalTabsEl.addEventListener("click", (event) => {
        const tabBtn = event.target.closest(".terminal-tab");
        if (!tabBtn) {
          return;
        }
        const tabId = parseInt(tabBtn.dataset.tab, 10);
        ensureTerminalFrame(tabId);
        activateTerminalTab(tabId);
      });

      terminalTabAdd.addEventListener("click", () => {
        if (tabCount >= maxTabs) {
          return;
        }
        tabCount += 1;
        const tabId = tabCount;
        // Read at click time, not page load - terminalNodePicker only
        // exists at all when worker_nodes was non-empty at render time
        // (question_view.py); its own <option> default ("control-plane")
        // reproduces today's exact behavior when the picker is absent.
        const nodeTarget = terminalNodePicker ? terminalNodePicker.value : "control-plane";

        const btn = document.createElement("button");
        btn.type = "button";
        btn.role = "tab";
        btn.className = "terminal-tab";
        btn.dataset.tab = String(tabId);
        btn.id = `terminal-tab-${tabId}`;
        btn.setAttribute("aria-controls", `terminal-frame-${tabId}`);
        btn.textContent = nodeTarget === "control-plane" ? `Terminal ${tabId}` : `Terminal ${tabId} (${nodeTarget})`;
        terminalTabsEl.insertBefore(btn, terminalTabAdd);

        ensureTerminalFrame(tabId, nodeTarget);
        activateTerminalTab(tabId);

        if (tabCount >= maxTabs) {
          terminalTabAdd.disabled = true;
        }
      });
    }

    // --- Resizable workspace, v3: two independent axes -------------------
    // Terminal moved to a full-height right column, Task stacked directly
    // above Checklist in the left column (style.css's "v3" comment on
    // .layout has the full picture). Both drag handles use the same
    // mechanism v1's single column-resize axis did: two explicit pixel
    // tracks that always sum to a fixed total, read back via
    // getComputedStyle so a `fr`-sized default resolves to real pixels
    // before the first drag ever touches it.
    //   - data-resize-index="0": column-width drag between the left column
    //     and Terminal. Only rendered when a terminal exists at all.
    //   - data-resize-index="1": row-height drag between Task and
    //     Checklist, within the left column. Always rendered, terminal or
    //     not - Task/Checklist stack regardless.
    // Two independent localStorage keys (one per axis) rather than one
    // shared shape, same reasoning v2 used: conflating them would need
    // exactly the kind of shape-guessing this mechanism avoids by keeping
    // each axis's array meaning fixed (always 3 tracks, always that axis).
    const MIN_COL_PX = 220;
    const MIN_ROW_PX = 180;
    const COL_STORAGE_KEY = "clusterdrill-layout-columns";
    const ROW_STORAGE_KEY = "clusterdrill-layout-rows";

    function currentColumnPx() {
      const style = window.getComputedStyle(layoutEl);
      return style.gridTemplateColumns.split(" ").map((v) => parseFloat(v));
    }

    function applyColumnPx(px) {
      layoutEl.style.gridTemplateColumns = px.map((v) => `${v}px`).join(" ");
      layoutEl.classList.add("js-resized");
    }

    function persistColumns(px) {
      try {
        localStorage.setItem(COL_STORAGE_KEY, JSON.stringify(px));
      } catch {
        /* localStorage unavailable (private browsing, etc.) - resizing
           still works for this page view, it just won't persist. */
      }
    }

    function restoreColumns() {
      let saved;
      try {
        saved = JSON.parse(localStorage.getItem(COL_STORAGE_KEY) || "null");
      } catch {
        saved = null;
      }
      // Always exactly 3 column tracks (left column, handle, terminal) -
      // only ever restored when a terminal column actually exists (see the
      // querySelector guard below), so there's nothing to disambiguate.
      if (!Array.isArray(saved) || saved.length !== 3) return;
      applyColumnPx(saved);
    }

    function currentRowPx() {
      const style = window.getComputedStyle(layoutEl);
      return style.gridTemplateRows.split(" ").map((v) => parseFloat(v));
    }

    function applyRowPx(px) {
      layoutEl.style.gridTemplateRows = px.map((v) => `${v}px`).join(" ");
      layoutEl.classList.add("js-resized-rows");
    }

    function persistRows(px) {
      try {
        localStorage.setItem(ROW_STORAGE_KEY, JSON.stringify(px));
      } catch {
        /* ignore, same as persistColumns */
      }
    }

    function restoreRows() {
      let saved;
      try {
        saved = JSON.parse(localStorage.getItem(ROW_STORAGE_KEY) || "null");
      } catch {
        saved = null;
      }
      // Always exactly 3 row tracks (Task, handle, Checklist).
      if (!Array.isArray(saved) || saved.length !== 3) return;
      applyRowPx(saved);
    }

    document.querySelectorAll(".resizer").forEach((handle) => {
      const index = parseInt(handle.dataset.resizeIndex, 10);
      let dragging = false;
      let lastPos = 0;

      if (index === 0) {
        // Column resize: left column <-> terminal. Track array is always
        // [left, handle, terminal] - indices 0 and 2.
        function resizeColBy(deltaPx) {
          const px = currentColumnPx();
          if (px.length < 3) return;
          const a = px[0] + deltaPx;
          const b = px[2] - deltaPx;
          if (a < MIN_COL_PX || b < MIN_COL_PX) return;
          px[0] = a;
          px[2] = b;
          applyColumnPx(px);
          persistColumns(px);
        }

        handle.addEventListener("mousedown", (e) => {
          dragging = true;
          lastPos = e.clientX;
          handle.classList.add("resizing");
          document.body.style.userSelect = "none";
          document.body.style.cursor = "col-resize";
        });
        window.addEventListener("mousemove", (e) => {
          if (!dragging) return;
          const deltaPx = e.clientX - lastPos;
          lastPos = e.clientX;
          resizeColBy(deltaPx);
        });
        window.addEventListener("mouseup", () => {
          if (!dragging) return;
          dragging = false;
          handle.classList.remove("resizing");
          document.body.style.userSelect = "";
          document.body.style.cursor = "";
        });
        handle.addEventListener("keydown", (e) => {
          if (e.key === "ArrowLeft") {
            resizeColBy(e.shiftKey ? -96 : -24);
            e.preventDefault();
          } else if (e.key === "ArrowRight") {
            resizeColBy(e.shiftKey ? 96 : 24);
            e.preventDefault();
          }
        });
      } else if (index === 1) {
        // Row resize: Task <-> Checklist. Track array is always
        // [task, handle, checklist] - indices 0 and 2, same mechanism as
        // the column axis just along Y.
        function resizeRowBy(deltaPx) {
          const px = currentRowPx();
          if (px.length < 3) return;
          const a = px[0] + deltaPx;
          const b = px[2] - deltaPx;
          if (a < MIN_ROW_PX || b < MIN_ROW_PX) return;
          px[0] = a;
          px[2] = b;
          applyRowPx(px);
          persistRows(px);
        }

        handle.addEventListener("mousedown", (e) => {
          dragging = true;
          lastPos = e.clientY;
          handle.classList.add("resizing");
          document.body.style.userSelect = "none";
          document.body.style.cursor = "row-resize";
        });
        window.addEventListener("mousemove", (e) => {
          if (!dragging) return;
          const deltaPx = e.clientY - lastPos;
          lastPos = e.clientY;
          resizeRowBy(deltaPx);
        });
        window.addEventListener("mouseup", () => {
          if (!dragging) return;
          dragging = false;
          handle.classList.remove("resizing");
          document.body.style.userSelect = "";
          document.body.style.cursor = "";
        });
        handle.addEventListener("keydown", (e) => {
          if (e.key === "ArrowUp") {
            resizeRowBy(e.shiftKey ? -96 : -24);
            e.preventDefault();
          } else if (e.key === "ArrowDown") {
            resizeRowBy(e.shiftKey ? 96 : 24);
            e.preventDefault();
          }
        });
      }
    });

    if (layoutEl && layoutEl.querySelector('.resizer[data-resize-index="0"]')) {
      restoreColumns();
    }
    if (layoutEl && layoutEl.querySelector('.resizer[data-resize-index="1"]')) {
      restoreRows();
    }

    // --- Session lifecycle: End session + timer auto-end ------------------
    // "End session" clears the server-side active session (app.py's
    // POST /sessions/end) and returns to the topic-lab landing page - the
    // explicit lab-lifecycle action a real timed lab needs, alongside the
    // automatic countdown. This never touches the cluster or any question's
    // namespace: it only changes which qids are
    // "in play" for navigation, nothing check.sh/reset touch.
    const isExamSession = body.dataset.isExam === "true";

    async function endSession(reason) {
      // Exam mode: "ending" is submitting - every question gets
      // graded once, server-side, right now (no more live feedback after
      // this than there was before it) - then on to the
      // results view instead of back to the topic-lab landing page. Both
      // the manual button (relabeled "Submit Exam" in the template) and
      // the timer-expiry auto-end below share this same function, so
      // submitting on timeout "just works" without its own wiring.
      if (isExamSession) {
        try {
          const res = await fetch("/sessions/submit", { method: "POST", headers: csrfHeaders() });
          if (res.ok) {
            window.location.href = "/sessions/results";
            return;
          }
        } catch {
          // Fall through to the alert below - the exam session is left
          // active (submit_exam never got to session_store.clear()), so a
          // retry from this same page is still possible.
        }
        alert("Submitting the exam failed - your session is still active, try again.");
        return;
      }
      try {
        await fetch("/sessions/end", { method: "POST", headers: csrfHeaders() });
      } catch {
        // Best-effort - even if the request fails, still send the user back
        // to the landing page rather than leaving them stuck.
      }
      window.location.href = "/topics" + (reason ? `?ended=${encodeURIComponent(reason)}` : "");
    }

    const endSessionBtn = document.getElementById("end-session-btn");
    if (endSessionBtn) {
      endSessionBtn.addEventListener("click", () => endSession("manual"));
    }

    // Leaving via the logo/home link used to just silently navigate to
    // /topics with the session still active in the background (resumable
    // from there, but easy to not notice you'd left it running) - a real
    // timed lab shouldn't have an ambiguous "did I leave or not" state.
    // Confirm and end it outright if you say yes; Cancel keeps you right
    // here, mid-question, exactly as if you'd never clicked.
    const homeLink = document.querySelector(".home-link");
    if (homeLink && body.dataset.inSession === "true") {
      homeLink.addEventListener("click", async (event) => {
        event.preventDefault();
        if (await confirmAction("You have an active session running. Leave and end it?", "Leave and end it")) {
          endSession("left");
        }
      });
    }

    // Live countdown. The deadline itself is server-authoritative - baked
    // into ActiveSession at session-start (sessions.py) and rendered into
    // body[data-timer-deadline] by question.html, unchanged by navigation
    // or a page refresh. This code only computes "how much of that fixed
    // deadline is left right now" and re-renders it once a second. When it
    // reaches zero, the session ends automatically (mirroring a real timed
    // lab shutting down) - this is a lifecycle/UI change, not a grading
    // one: it never calls /check or /reset itself.
    const timerBadge = document.getElementById("timer-badge");
    const timerValueEl = document.getElementById("timer-value");
    const deadlineRaw = body.dataset.timerDeadline;

    if (timerBadge && timerValueEl && deadlineRaw) {
      const deadlineMs = parseFloat(deadlineRaw) * 1000;

      function formatRemaining(ms) {
        const totalSeconds = Math.max(0, Math.floor(ms / 1000));
        const h = Math.floor(totalSeconds / 3600);
        const m = Math.floor((totalSeconds % 3600) / 60);
        const s = totalSeconds % 60;
        const mm = String(m).padStart(2, "0");
        const ss = String(s).padStart(2, "0");
        return h > 0 ? `${h}:${mm}:${ss}` : `${mm}:${ss}`;
      }

      function updateTimer() {
        const remainingMs = deadlineMs - Date.now();
        if (remainingMs <= 0) {
          timerValueEl.textContent = "time's up";
          timerBadge.classList.add("timer-expired");
          timerBadge.classList.remove("timer-low");
          timerBadge.setAttribute("title", "The session timer reached zero - ending the session.");
          clearInterval(intervalId);
          endSession("timeup");
          return;
        }
        timerValueEl.textContent = formatRemaining(remainingMs);
        timerBadge.classList.toggle("timer-low", remainingMs <= 5 * 60 * 1000);
      }

      updateTimer();
      const intervalId = setInterval(updateTimer, 1000);
    }
  }

  // --- Click-to-copy for Task/Hint/Solution code (practice page only) -----
  // Every value the candidate is meant to retype - a namespace, a pod name,
  // a `100m`-style resource limit, a full manifest in the Solution tab -
  // is markdown inline `code` or a fenced code block in QUESTION.md/
  // ANSWER.md, already rendered server-side into the DOM on page load (see
  // question.html's task_html/hint_html/answer_html panels). This block
  // only adds click handlers on top of that existing markup: no server
  // change, and it never touches grading (same invariant as everywhere
  // else in this file) - purely a typo-avoidance affordance.
  const tabContentEls = document.querySelectorAll(".tab-content");
  if (tabContentEls.length) {
    function copyText(text) {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        return navigator.clipboard.writeText(text).catch(() => fallbackCopy(text));
      }
      return Promise.resolve(fallbackCopy(text));
    }

    // Clipboard API needs a secure context (https, or localhost) - falls
    // back to the old hidden-textarea + execCommand trick so copy still
    // works over a plain-http LAN/tunnel hop that isn't https itself.
    function fallbackCopy(text) {
      const ta = document.createElement("textarea");
      ta.value = text;
      ta.style.position = "fixed";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.select();
      try { document.execCommand("copy"); } catch { /* nothing left to try */ }
      document.body.removeChild(ta);
    }

    function flash(el, revert) {
      clearTimeout(el._copyTimeout);
      el.classList.add("copied");
      el._copyTimeout = setTimeout(() => {
        el.classList.remove("copied");
        if (revert) revert();
      }, 1100);
    }

    tabContentEls.forEach((tabContent) => {
      // Fenced code blocks (Solution tab's manifest/command, mainly): one
      // "Copy" button per block, copying the whole block's text rather than
      // requiring a manual select-all. Wrapping in a .code-block div (not
      // styling <pre> itself) keeps the button's position:absolute
      // corner-anchor independent of <pre>'s own padding/overflow-x rules.
      tabContent.querySelectorAll("pre").forEach((pre) => {
        const wrapper = document.createElement("div");
        wrapper.className = "code-block";
        pre.parentNode.insertBefore(wrapper, pre);
        wrapper.appendChild(pre);

        const btn = document.createElement("button");
        btn.type = "button";
        btn.className = "code-copy-btn";
        btn.textContent = "Copy";
        wrapper.insertBefore(btn, pre);

        btn.addEventListener("click", () => {
          copyText(pre.textContent);
          const original = btn.textContent;
          btn.textContent = "Copied!";
          flash(btn, () => { btn.textContent = original; });
        });
      });

      // Inline `code` values everywhere else in Task/Hint/Solution -
      // namespace names, pod/resource names, image tags, `100m`/`128Mi`
      // style limits. Excludes anything inside a <pre> (handled above by
      // the whole-block button instead, copying it individually too would
      // be redundant).
      tabContent.querySelectorAll("code").forEach((codeEl) => {
        if (codeEl.closest("pre")) return;
        codeEl.classList.add("copyable-code");
        codeEl.setAttribute("tabindex", "0");
        codeEl.setAttribute("role", "button");
        codeEl.title = "Click to copy";
        codeEl.addEventListener("click", () => {
          copyText(codeEl.textContent);
          flash(codeEl);
        });
        codeEl.addEventListener("keydown", (event) => {
          if (event.key === "Enter" || event.key === " ") {
            event.preventDefault();
            codeEl.click();
          }
        });
      });
    });
  }

  // --- Skill radar chart (Progress page only) ---------------------
  // Plain inline SVG built by hand from the JSON the route already embedded
  // in the page (progress.html's #radar-data script tag) - the one
  // component in this redesign that genuinely needs SVG (a filled polygon
  // isn't a pure-CSS shape), consistent with the no-chart-library,
  // no-bundler posture everywhere else in this app.
  const radarWrap = document.getElementById("radar-chart-wrap");
  const radarDataEl = document.getElementById("radar-data");
  if (radarWrap && radarDataEl) {
    let domains = [];
    try {
      domains = JSON.parse(radarDataEl.textContent || "[]");
    } catch {
      domains = [];
    }

    if (domains.length < 3) {
      // Shares .empty-state (style.css) with the server-rendered empty
      // states in mock_exam.html/topic_detail.html, rather than an
      // inline-styled one-off string - see _macros.html's empty_state().
      radarWrap.innerHTML = '<p class="empty-state">' +
        'Answer at least 3 domains\' worth of questions to see a radar chart here.</p>';
    } else {
      const size = 260;
      const center = size / 2;
      const maxRadius = center - 40;
      const axisCount = domains.length;

      function pointFor(index, valuePct) {
        const angle = (Math.PI * 2 * index) / axisCount - Math.PI / 2;
        const r = (maxRadius * Math.max(0, Math.min(100, valuePct))) / 100;
        return [center + r * Math.cos(angle), center + r * Math.sin(angle)];
      }

      const svgNS = "http://www.w3.org/2000/svg";
      const svg = document.createElementNS(svgNS, "svg");
      svg.setAttribute("class", "radar-chart");
      svg.setAttribute("width", size);
      svg.setAttribute("height", size);
      svg.setAttribute("viewBox", `0 0 ${size} ${size}`);

      // Axis lines + short domain labels (abbreviated - full names shown
      // via <title> tooltip, the labels themselves would overlap badly at
      // this size with the full CNCF domain strings).
      domains.forEach((d, i) => {
        const [ax, ay] = pointFor(i, 100);
        const line = document.createElementNS(svgNS, "line");
        line.setAttribute("class", "radar-axis");
        line.setAttribute("x1", center);
        line.setAttribute("y1", center);
        line.setAttribute("x2", ax);
        line.setAttribute("y2", ay);
        svg.appendChild(line);

        const [lx, ly] = pointFor(i, 116);
        const label = document.createElementNS(svgNS, "text");
        label.setAttribute("x", lx);
        label.setAttribute("y", ly);
        label.setAttribute("text-anchor", "middle");
        label.setAttribute("dominant-baseline", "middle");
        const short = d.name.split(",")[0].replace("Application ", "App. ");
        label.textContent = short.length > 18 ? short.slice(0, 17) + "…" : short;
        const title = document.createElementNS(svgNS, "title");
        title.textContent = `${d.name}: ${d.pct}%`;
        label.appendChild(title);
        svg.appendChild(label);
      });

      const points = domains.map((d, i) => pointFor(i, d.pct).join(",")).join(" ");
      const polygon = document.createElementNS(svgNS, "polygon");
      polygon.setAttribute("class", "radar-fill");
      polygon.setAttribute("points", points);
      svg.appendChild(polygon);

      radarWrap.appendChild(svg);
    }
  }
})();

// --- Idle lifecycle: real cluster-access enforcement -------------------------
// Distinct from the "no practice session" badge (sessions.py bookkeeping) -
// this is what actually keeps a forgotten, publicly-reachable terminal from
// staying connected to the real cluster forever. The server (idle.py +
// app.py's /heartbeat, /idle-status, and the idle watchdog) is authoritative:
// it is the thing that actually kills the tmux sessions and revokes the
// login cookie once nobody's touched the keyboard for too long. Everything
// here just (a) feeds it genuine activity signals, throttled, and (b)
// renders the warning/kill state it reports back. A dropped fetch() or a
// closed laptop lid can't prevent the kill - the watchdog runs server-side
// on its own clock regardless of whether this JS ever sends another
// heartbeat again.
//
// Runs unconditionally (not gated on any page-specific element) since it's
// loaded on every page that has app.js - the only per-page-optional piece is
// the warning banner itself, which question.html renders and progress.html
// (also loads app.js) does not; this code no-ops gracefully wherever it's
// missing.
(function () {
  const ACTIVITY_EVENTS = ["mousemove", "mousedown", "keydown", "scroll", "touchstart", "wheel"];
  const HEARTBEAT_MIN_INTERVAL_MS = 15000;
  const POLL_INTERVAL_MS = 15000;

  let lastHeartbeatSent = 0;
  let heartbeatInFlight = false;
  let killAtMs = null;
  let warnAtMs = null;

  const idleWarning = document.getElementById("idle-warning");
  const idleCountdownEl = document.getElementById("idle-countdown");
  const idleDismissBtn = document.getElementById("idle-dismiss-btn");

  function redirectToLogin() {
    window.location.href = "/login?idle=1";
  }

  function applyStatus(data) {
    if (!data || data.enabled === false) {
      killAtMs = null;
      warnAtMs = null;
      return;
    }
    if (data.killed) {
      redirectToLogin();
      return;
    }
    killAtMs = data.kill_at * 1000;
    warnAtMs = data.warn_at * 1000;
  }

  async function pollIdleStatus() {
    try {
      const res = await fetch("/idle-status", { cache: "no-store" });
      if (res.status === 401) {
        redirectToLogin();
        return;
      }
      if (res.ok) applyStatus(await res.json());
    } catch {
      // Network hiccup - the next poll tick will retry; the server-side
      // watchdog doesn't need this request to succeed to do its job.
    }
  }

  async function sendHeartbeat() {
    if (heartbeatInFlight) return;
    heartbeatInFlight = true;
    try {
      const res = await fetch("/heartbeat", { method: "POST", cache: "no-store", headers: csrfHeaders() });
      if (res.status === 401) {
        redirectToLogin();
        return;
      }
      if (res.ok) applyStatus(await res.json());
    } catch {
      // Best-effort - see pollIdleStatus's comment above.
    } finally {
      heartbeatInFlight = false;
    }
  }

  function onActivity() {
    const now = Date.now();
    if (now - lastHeartbeatSent < HEARTBEAT_MIN_INTERVAL_MS) return;
    lastHeartbeatSent = now;
    sendHeartbeat();
  }

  ACTIVITY_EVENTS.forEach((evt) => window.addEventListener(evt, onActivity, { passive: true }));

  if (idleDismissBtn && idleWarning) {
    idleDismissBtn.addEventListener("click", () => {
      idleWarning.hidden = true;
      lastHeartbeatSent = 0; // bypass the throttle - this is a deliberate "I'm here" click
      sendHeartbeat();
    });
  }

  function tick() {
    if (!idleWarning || killAtMs === null || warnAtMs === null) return;
    const now = Date.now();
    if (now >= killAtMs) {
      redirectToLogin();
      return;
    }
    if (now >= warnAtMs) {
      idleWarning.hidden = false;
      const totalSeconds = Math.max(0, Math.floor((killAtMs - now) / 1000));
      const m = Math.floor(totalSeconds / 60);
      const s = totalSeconds % 60;
      if (idleCountdownEl) idleCountdownEl.textContent = `${m}:${String(s).padStart(2, "0")}`;
    } else {
      idleWarning.hidden = true;
    }
  }

  pollIdleStatus();
  setInterval(pollIdleStatus, POLL_INTERVAL_MS);
  setInterval(tick, 1000);
})();
