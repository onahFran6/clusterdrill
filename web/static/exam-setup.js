"use strict";

const examForm = document.getElementById("exam-setup-form");

function syncExamSelection() {
  let valid = true;
  for (const name of ["topics", "difficulties"]) {
    const inputs = [...examForm.querySelectorAll(`input[name="${name}"]`)];
    const count = inputs.filter(input => input.checked).length;
    examForm.querySelector(`[data-selection-summary="${name}"]`).textContent = `${count} of ${inputs.length} selected`;
    valid &&= count > 0;
  }
  examForm.querySelector('button[type="submit"]').disabled = !valid || examForm.dataset.available !== "true";
  document.getElementById("exam-selection-help").textContent = valid ? "" : "Select at least one topic and one difficulty to start.";
}

if (examForm) {
  examForm.addEventListener("change", syncExamSelection);
  examForm.addEventListener("click", event => {
    const action = event.target.closest("[data-select-topics]");
    if (!action) return;
    for (const input of examForm.querySelectorAll('input[name="topics"]')) {
      input.checked = action.dataset.selectTopics === "all";
    }
    syncExamSelection();
  });
  syncExamSelection();
}
