"use strict";

const selector = document.getElementById("topic-select");
const preview = document.getElementById("session-preview");
const previewContent = document.getElementById("preview-content");
const previewStatus = document.getElementById("preview-status");
let pendingPreview;
const drafts = new Map();

async function showTopic() {
  const option = selector.selectedOptions[0];
  if (!option?.value.startsWith("/topics/")) return;
  const link = { href: new URL(option.value, location.origin).href };
  document.getElementById("topic-summary").textContent = option.dataset.summary;
  const currentForm = previewContent.querySelector("form");
  if (currentForm && previewContent.dataset.topicUrl) {
    const values = new FormData(currentForm);
    drafts.set(previewContent.dataset.topicUrl, {
      difficulty: values.get("difficulty"),
      timer_minutes: values.get("timer_minutes"),
      session_size: values.get("session_size"),
    });
  }
  pendingPreview?.abort();
  const request = new AbortController();
  pendingPreview = request;
  preview.hidden = false;
  preview.setAttribute("aria-busy", "true");
  previewContent.inert = true;
  previewStatus.textContent = `Loading ${option.textContent.trim()} settings…`;
  previewContent.replaceChildren();
  try {
    const response = await fetch(link.href, { signal: request.signal });
    if (!response.ok) throw new Error("Topic could not be loaded");
    const html = await response.text();
    if (request.signal.aborted) return;
    const page = new DOMParser().parseFromString(html, "text/html");
    const setup = page.querySelector(".practice-setup");
    const title = page.querySelector(".topic-detail-heading .page-title");
    const titleDescription = page.querySelector(".topic-detail-heading .hub-intro");
    if (!setup || !title || !titleDescription) throw new Error("Session settings are unavailable");
    const heading = document.createElement("h3");
    heading.className = "preview-title";
    heading.tabIndex = -1;
    heading.textContent = title.textContent.trim();
    const description = document.createElement("p");
    description.className = "preview-description";
    description.textContent = titleDescription.textContent.trim();
    const browse = document.createElement("a");
    browse.href = link.href;
    browse.className = "preview-link";
    browse.textContent = "Browse questions and topic challenges →";
    const primary = setup.querySelector('button[value="fixed"]');
    if (primary) primary.textContent = "Start practice";
    const form = setup.querySelector("form");
    const draft = drafts.get(link.href);
    if (draft && form) {
      for (const [name, value] of Object.entries(draft)) {
        const field = form.elements.namedItem(name);
        if (field) field.value = value;
      }
    }
    window.syncPracticeSetup?.(form);
    previewContent.replaceChildren(heading, description, setup, browse);
    previewContent.dataset.topicUrl = link.href;
    previewContent.classList.remove("preview-enter");
    // Restart the reveal for consecutive selections without delaying interaction.
    void previewContent.offsetWidth;
    previewContent.classList.add("preview-enter");
    previewStatus.textContent = `${heading.textContent} session settings ready.`;
  } catch (error) {
    if (error.name === "AbortError") return;
    delete previewContent.dataset.topicUrl;
    const heading = document.createElement("h3");
    heading.className = "preview-title";
    heading.tabIndex = -1;
    heading.textContent = "Settings unavailable";
    const message = document.createElement("p");
    message.className = "preview-description";
    message.textContent = "This topic's settings could not load. Open the topic page to start a session, or choose another topic.";
    const fallback = document.createElement("a");
    fallback.href = link.href;
    fallback.className = "btn btn-secondary";
    fallback.textContent = "Open topic page →";
    previewContent.replaceChildren(heading, message, fallback);
    previewStatus.textContent = "The preview could not load. Open the topic page to continue.";
  } finally {
    if (!request.signal.aborted) {
      preview.setAttribute("aria-busy", "false");
      previewContent.inert = false;
    }
  }
}

selector.addEventListener("change", showTopic);
showTopic();

const scopeControl = document.querySelector(".practice-scope");
const mixedSetup = document.getElementById("selected-topics-setup");
const mixedForm = mixedSetup.querySelector("form");
const topicChoices = [...mixedForm.querySelectorAll('input[name="topics"]')];

function syncSelectedTopics() {
  const selected = topicChoices.filter(input => input.checked);
  const counts = { all: 0, easy: 0, medium: 0, hard: 0 };
  for (const input of selected) {
    const topicCounts = JSON.parse(input.dataset.counts);
    for (const level of Object.keys(counts)) counts[level] += topicCounts[level];
  }
  for (const input of mixedForm.querySelectorAll('input[name="difficulty"]')) {
    const count = counts[input.value || "all"];
    input.closest("label").querySelector("small").textContent = count;
    input.disabled = count === 0;
    if (input.checked && input.disabled) mixedForm.querySelector('input[name="difficulty"][value=""]').checked = true;
  }
  const difficulty = mixedForm.querySelector('input[name="difficulty"]:checked').value || "all";
  const count = counts[difficulty];
  mixedForm.querySelector('button[type="submit"]').disabled = count === 0;
  document.getElementById("selected-topics-summary").textContent = selected.length
    ? `${selected.length} ${selected.length === 1 ? "topic" : "topics"} selected · ${count} matching questions`
    : "Choose at least one topic.";
  window.syncPracticeSetup(mixedForm);
}

scopeControl.hidden = false;
scopeControl.addEventListener("click", event => {
  const button = event.target.closest("[data-practice-scope]");
  if (!button) return;
  const single = button.dataset.practiceScope === "single";
  document.getElementById("single-topic-setup").hidden = !single;
  mixedSetup.hidden = single;
  for (const choice of scopeControl.querySelectorAll("button")) {
    choice.setAttribute("aria-pressed", String(choice === button));
  }
  if (!single && !topicChoices.some(input => input.checked)) {
    const topic = selector.selectedOptions[0]?.value.replace("/topics/", "");
    const input = topicChoices.find(input => input.value === topic);
    if (input) input.checked = true;
    syncSelectedTopics();
  }
});
mixedForm.addEventListener("change", syncSelectedTopics);
mixedForm.addEventListener("click", event => {
  const button = event.target.closest("[data-select-topics]");
  if (!button) return;
  for (const input of topicChoices) input.checked = button.dataset.selectTopics === "all";
  syncSelectedTopics();
});
syncSelectedTopics();
