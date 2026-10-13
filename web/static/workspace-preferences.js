// Runs in <head> so a hidden terminal never flashes or starts a connection.
// Display preferences are shared by tabs/accounts on this browser origin.
(() => {
  const key = "clusterdrill-workspace-v3";
  const previousKey = "clusterdrill-workspace-v2";
  const defaults = { version: 3, terminalVisible: true, questionFraction: 0.58, taskFraction: null };
  const validFraction = (value) => typeof value === "number" && Number.isFinite(value) && value >= 0.2 && value <= 0.8;
  let state = { ...defaults };
  try {
    const saved = JSON.parse(localStorage.getItem(key) || localStorage.getItem(previousKey) || "null");
    if (saved?.version === 3) {
      if (typeof saved.terminalVisible === "boolean") state.terminalVisible = saved.terminalVisible;
      for (const field of ["questionFraction", "taskFraction"]) {
        if (validFraction(saved[field])) state[field] = saved[field];
      }
    } else if (saved?.version === 2) {
      // v3 restores the content-sized checklist as the default. Keep the
      // user's terminal and column preferences, but discard the old row
      // split that left a large empty checklist panel on first load.
      if (typeof saved.terminalVisible === "boolean") state.terminalVisible = saved.terminalVisible;
      if (validFraction(saved.questionFraction)) state.questionFraction = saved.questionFraction;
    } else {
      for (const [legacy, field] of [["columns", "questionFraction"], ["rows", "taskFraction"]]) {
        let tracks;
        try {
          tracks = JSON.parse(localStorage.getItem(`clusterdrill-layout-${legacy}`) || "null");
        } catch { continue; }
        if (Array.isArray(tracks) && tracks.length === 3 && tracks.every((n) => typeof n === "number" && Number.isFinite(n) && n > 0)) {
          const fraction = tracks[0] / (tracks[0] + tracks[2]);
          if (validFraction(fraction)) state[field] = fraction;
        }
      }
      localStorage.setItem(key, JSON.stringify(state));
      localStorage.removeItem("clusterdrill-layout-columns");
      localStorage.removeItem("clusterdrill-layout-rows");
    }
    localStorage.setItem(key, JSON.stringify(state));
    localStorage.removeItem(previousKey);
  } catch { /* Storage may be unavailable; keep usable in-memory defaults. */ }

  function apply() {
    const root = document.documentElement;
    root.classList.toggle("terminal-preference-hidden", !state.terminalVisible);
    root.style.setProperty("--question-track", `${state.questionFraction}fr`);
    root.style.setProperty("--terminal-track", `${1 - state.questionFraction}fr`);
    root.style.setProperty("--task-track", state.taskFraction === null ? "1fr" : `${state.taskFraction}fr`);
    root.style.setProperty("--checklist-track", state.taskFraction === null ? "auto" : `${1 - state.taskFraction}fr`);
  }
  window.clusterdrillWorkspace = {
    get: () => ({ ...state }),
    update(patch) {
      state = { ...state, ...patch };
      apply();
      try { localStorage.setItem(key, JSON.stringify(state)); } catch { /* Keep working without persistence. */ }
    },
  };
  apply();
})();
