"use strict";

function matchingPool(form, mode = form.dataset.practiceMode || "fixed") {
  const checked = form.querySelector('input[name="difficulty"]:checked');
  const count = Number(checked?.closest("label")?.querySelector("small")?.textContent);
  if (form.hasAttribute("data-selected-topics")) return count;
  if (mode === "mixed") {
    const mixedCount = Number(checked?.dataset.mixedCount);
    return Number.isInteger(mixedCount) && mixedCount > 0 ? mixedCount : null;
  }
  return Number.isInteger(count) && count > 0 ? count : null;
}

function markShortcuts(form) {
  for (const shortcut of form.querySelectorAll("[data-input-target]")) {
    const input = form.elements.namedItem(shortcut.dataset.inputTarget);
    const selected = input instanceof HTMLInputElement && input.value === shortcut.dataset.inputValue;
    shortcut.classList.toggle("is-selected", selected);
    shortcut.setAttribute("aria-pressed", selected ? "true" : "false");
  }
}

// The typed count stays in charge. Difficulty only changes the ceiling and
// which preset buttons still fit that pool.
function syncPracticeSetup(form, mode = form.dataset.practiceMode || "fixed") {
  if (!(form instanceof HTMLFormElement)) return;
  const ceiling = matchingPool(form, mode);
  const countInput = form.elements.namedItem("session_size");
  if (ceiling !== null && countInput instanceof HTMLInputElement) {
    countInput.max = String(ceiling);
    if (ceiling > 0 && Number(countInput.value) > ceiling) countInput.value = String(ceiling);
    const unit = form.querySelector("[data-count-ceiling]");
    if (unit) unit.textContent = `up to ${ceiling}`;
    const help = form.querySelector('[id$="practice-count-help"]');
    if (help) help.textContent = form.hasAttribute("data-selected-topics")
      ? "Limited to questions matching your selected topics and difficulty."
      : mode === "mixed"
      ? "Mixed practice can draw from every matching topic."
      : "Limited to questions matching this topic and difficulty.";
    const all = form.querySelector("[data-count-all]");
    if (all) {
      all.dataset.inputValue = String(ceiling);
      all.textContent = `All ${ceiling}`;
    }
    for (const shortcut of form.querySelectorAll('[data-input-target="session_size"]:not([data-count-all])')) {
      shortcut.hidden = Number(shortcut.dataset.inputValue) > ceiling;
    }
  }
  markShortcuts(form);
}

window.syncPracticeSetup = syncPracticeSetup;

document.addEventListener("click", (event) => {
  const modeButton = event.target.closest('button[name="mode"]');
  if (modeButton?.form?.querySelector("[data-mixed-count]")) {
    modeButton.form.dataset.practiceMode = modeButton.value;
    syncPracticeSetup(modeButton.form, modeButton.value);
  }
  const shortcut = event.target.closest("[data-input-target]");
  if (!shortcut || shortcut.hidden) return;
  const input = shortcut.closest("form")?.elements.namedItem(shortcut.dataset.inputTarget);
  if (!(input instanceof HTMLInputElement)) return;
  input.value = shortcut.dataset.inputValue;
  input.dispatchEvent(new Event("input", { bubbles: true }));
  input.focus({ preventScroll: true });
});

document.addEventListener("change", (event) => {
  if (event.target instanceof HTMLInputElement && event.target.name === "difficulty") {
    syncPracticeSetup(event.target.form);
  }
});

document.addEventListener("input", (event) => {
  const input = event.target;
  if (input instanceof HTMLInputElement && input.form?.querySelector("[data-input-target]")) {
    markShortcuts(input.form);
  }
});

for (const form of document.querySelectorAll("form.practice-setup-form")) syncPracticeSetup(form);
