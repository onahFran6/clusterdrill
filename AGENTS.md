# ClusterDrill

A lab-style CKAD question bank: per-topic pools of hands-on questions, each graded against live
cluster state (a local Minikube appliance, or any dedicated disposable cluster you point it at).
See `README.md` for the full quick start, architecture, and layout.

This is a public repo (`onahFran6/clusterdrill`), extracted from a private monorepo
(`kcad-aws-workspace`). Treat it as standalone: don't assume access to that monorepo's docs,
history, or internal automation (bb-factory, agent-trunk, etc.) - none of that applies here.

## Layout

- `clusterdrill/` - the installable CLI package (`clusterdrill/cli.py`), the local Minikube
  appliance lifecycle (`clusterdrill local doctor|init|...`), and release/manifest/Helm-chart
  logic (`release.py`, `manifests/`, `helm/`). Its own tests live in `clusterdrill/tests/`.
- `web/` - the FastAPI app served inside the appliance: `app.py` wires up `routers/`, with
  `auth.py`, `rbac.py`, `sessions.py`, `questions.py`, `topology.py`, `ttyd_manager.py` as the
  main modules. Has its own venv/requirements, separate from the top-level package.
- `questions/<topic>/qNNN-slug/` - the question bank content itself (`QUESTION.md`, `setup.sh`,
  `check.sh`, `ANSWER.md`); see `CONTRIBUTING.md` for the folder shape.
- `tests/e2e/` - Playwright-based end-to-end tests, separate `requirements.txt` (browser
  binaries required, not installed by the default dev extras).
- `deploy/` - Helm chart / manifests for deploying the appliance outside the CLI's own flow.

## Licensing boundary

This repo mixes MIT-original content with GPL-3.0-ported content, isolated under
`questions/community/`. Never mix the two in the same question folder:

- MIT question directories must not copy, port, or adapt content from `questions/community/` or
  any other GPL-3.0 source.
- `questions/community/` (GPL-3.0) must not receive MIT-licensed content.

Read the [Licensing section of the README](README.md#licensing) before touching `questions/`.

## Content rule

No question - original or community-contributed - may be reconstructed from someone's memory of
an actual CKAD exam session (see `CONTRIBUTING.md`). Source new questions from the
[CNCF CKAD curriculum](https://github.com/cncf/curriculum) and
[kubernetes.io/docs](https://kubernetes.io/docs/home/) only.

## Verification before opening a PR

- Question changes: `lib/verify-question.sh <question>`
- Web-app changes: `web/.venv/bin/pytest web/tests`
- Python: `ruff check .` and `yamllint .` (see `pyproject.toml` for scope/exclusions)
- JS/Markdown: `npm run lint:js` and `npm run lint:md`

Fill out `.github/PULL_REQUEST_TEMPLATE.md` for real, including the licensing-boundary checklist -
don't skip checklist items.

## Commits & PRs

Match this repo's existing `git log` style: one line, present tense/imperative, ticket-or-issue
reference where applicable, one concern per commit. Use the `good-commits` skill
(`~/.claude/skills/good-commits/`) when committing or opening a PR for atomic-commit splitting,
message quality, and PR description structure.

**Commit mode: confirm** - show the proposed commit split and message(s), and the drafted PR
description, before running `git commit` / `gh pr create`, on every branch, no exceptions.
