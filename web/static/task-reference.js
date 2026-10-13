// Reuse ANSWER.md's official docs citation as a practice aid without loading
// solution content in an exam, where the server deliberately omits it.
(() => {
  const page = document.body;
  const task = document.querySelector('.tab-panel[data-tab-panel="task"]');
  const solution = document.querySelector('.tab-panel[data-tab-panel="solution"]');
  if (!task || !solution || page.dataset.isExam === "true") return;

  const answerDocLink = solution.querySelector('a[href^="https://kubernetes.io/docs/"]');
  const answerDocText = solution.querySelector("p")?.textContent.trim() || "";
  const plainUrl = answerDocText.match(/(?:^|\s)(https:\/\/kubernetes\.io\/docs\/[^\s)]+)/)?.[1];
  let url;
  try {
    url = new URL(answerDocLink?.href || plainUrl || "");
  } catch {
    return;
  }
  if (url.hostname !== "kubernetes.io" || !url.pathname.startsWith("/docs/")) return;

  const reference = document.createElement("aside");
  reference.className = "task-reference";
  reference.setAttribute("aria-label", "Related documentation");

  const label = document.createElement("span");
  label.textContent = "REFERENCE";

  const link = document.createElement("a");
  link.href = url.href;
  link.target = "_blank";
  link.rel = "noopener noreferrer";
  link.append("Open relevant Kubernetes docs ");
  const icon = document.createElement("span");
  icon.setAttribute("aria-hidden", "true");
  icon.textContent = "↗";
  link.append(icon);

  reference.append(label, link);
  task.append(reference);
})();
