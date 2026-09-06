# Contributing to ClusterDrill

Thanks for considering a contribution. This document covers the two things
every content PR needs to get right - the folder shape a question must
follow, and the one hard rule about where question content is allowed to
come from - plus how to verify your work locally before opening a PR.

By contributing, you agree to license your changes under this project's
license for the directory you're contributing to (see
[Licensing](#licensing) below), and you confirm the content is your own
work or properly attributed per that section's rules.

## The one hard content rule

**No question in this bank - original or community-contributed - may be
reconstructed from someone's memory of an actual CKAD exam session.**

Every certification body running a performance-based exam (Linux
Foundation's CKAD/CKA/CKS included) has you agree to a confidentiality
clause: you don't disclose or reproduce the specific tasks you personally
saw during a real attempt. That's a contractual obligation on the person
who sat the exam, separate from copyright, and this project cannot accept
content that would put a contributor in breach of it - no matter how the
content is licensed or how well-intentioned the submission is.

This isn't actually a hard constraint in practice: CKAD is a
performance-based exam, not a fixed secret question bank the way an
old-style multiple-choice cert exam is. The domains and general task shapes
("create a Deployment with X," "configure a NetworkPolicy that does Y") are
publicly documented CNCF curriculum, not leaked material. Source every
question from the [CNCF CKAD curriculum](https://github.com/cncf/curriculum)
and [kubernetes.io/docs](https://kubernetes.io/docs/home/) - the same
approach every legitimate CKAD prep resource uses - never from recall of a
specific exam attempt, yours or anyone else's.

If you're porting a question from an existing open-source resource instead
of writing one from scratch, see [Licensing](#licensing) below - that's a
separate, orthogonal set of rules from this one.

## Folder shape

Every question lives at `questions/<topic>/qNNN-slug/`, alongside its
topic's other questions and one shared `domains.fragment.yaml`:

```text
questions/<topic>/
  domains.fragment.yaml     # every question in this topic: id, domain,
                             # difficulty, resource_kinds, points
  qNNN-slug/
    QUESTION.md              # task, docs-search hint, CNCF domain + points
    setup.sh                 # idempotent: creates/resets namespace qNNN, seeds resources
    check.sh                 # grading criteria against live cluster state
    ANSWER.md                # reference solution + a direct kubernetes.io/docs link
    diagram.mmd               # generated Mermaid diagram (leave to the diagram generator)
```

`questions/_template/` has a starting-point copy of each file with inline
guidance - copy it rather than starting from a blank file.

A new question also needs a matching entry appended to its topic's
`domains.fragment.yaml` (`id`, `domain` - one of the five CNCF domains,
`difficulty` - easy/medium/hard, `resource_kinds`, `points`). Validate the
fragment with:

```sh
lib/load-domains.sh --check
```

`check.sh` may only assert against **live cluster state** - it's read by
the grader as the one source of truth for pass/fail, never a proxy for
something a candidate merely claims to have done.

## Verify before opening a PR

`lib/verify-question.sh` is the gate every question must pass - it proves
`setup.sh`/`check.sh`/cleanup are all correct together, not just
individually plausible:

```sh
lib/verify-question.sh questions/<topic>/qNNN-slug
```

This resets to a fresh, unsolved state and confirms `check.sh` scores 0
(catching false positives), applies `ANSWER.md`'s reference solution and
confirms `check.sh` scores full marks (catching false negatives), then
resets again and confirms no leftover cluster objects remain labeled for
that question (catching incomplete cleanup). It needs a real reachable
cluster - `lib/bootstrap-minikube.sh` gets a local one ready if you don't
already have `KUBECONFIG` pointing at something suitable.

Paste this command's output in your PR per the PR template.

If your PR touches the web app (`web/`) instead of (or in addition to)
question content, run its test suite too:

```sh
web/.venv/bin/pytest web/tests
```

## Development environment and quality commands

Everything below runs from a fresh clone with no manual setup beyond the
listed prerequisites.
Prerequisites: Python 3.11+, Node.js 22+, Docker (only needed for the
Dockerfile lint), [ShellCheck](https://www.shellcheck.net/), and
[gitleaks](https://github.com/gitleaks/gitleaks) (`brew install shellcheck
gitleaks` / see each project's own install docs on Linux - neither is
pip/npm installable, so neither is in either dependency file below).

Install dev dependencies:

```sh
pip install -e '.[dev]'                    # clusterdrill CLI + its tests, ruff, yamllint
pip install -r web/requirements-dev.txt    # web app + its tests
npm install                                 # eslint, markdownlint-cli
```

Format and lint:

```sh
ruff format .                 # Python - not currently enforced repo-wide, see note below
ruff check .                  # Python lint (imports, unused names, style)
shellcheck -x -P lib deploy/entrypoint.sh tests/*.sh lib/*.sh
yamllint -c .yamllint.yml clusterdrill/manifests/*.yaml .github/ISSUE_TEMPLATE/*.yml
docker run --rm -i -v "$PWD/.hadolint.yaml:/.hadolint.yaml" hadolint/hadolint < Dockerfile
npm run lint:js
npm run lint:md
```

`ruff format` is deliberately not run as an enforced check yet: applying it
once would touch most Python files in the tree in a single pass (line
wrapping, docstring spacing) with no behavior change but a large,
hard-to-review diff. It's available for anyone who wants it locally; making
it mandatory is a separate, deliberate follow-up rather than something to
bundle into an unrelated change.

Secret scan (learner fixtures intentionally contain secret-*shaped*
values; see [`docs/adr/0003-secret-scanner-baseline.md`](docs/adr/0003-secret-scanner-baseline.md)
for the one documented exception in `.gitleaksignore`):

```sh
gitleaks detect --source . --no-git -v
```

Unit tests:

```sh
pytest clusterdrill/tests
pytest web/tests
```

Question-content validation (see [Verify before opening a PR](#verify-before-opening-a-pr)
above for the full explanation):

```sh
lib/load-domains.sh --check
lib/verify-question.sh questions/<topic>/qNNN-slug
```

Browser E2E (drives a real Minikube profile and a real Chromium browser via
Playwright - see `tests/e2e/test_appliance_e2e.py`'s module docstring for
what it covers and why test order matters):

```sh
cd tests/e2e
pip install -r requirements.txt && playwright install chromium
python -m pytest -q
```

### Dependency pinning and upgrade policy

Python dependencies use compatible-release pins (`~=X.Y`, allows patch/bugfix
bumps, blocks accidental minor/major breaks) in `pyproject.toml`'s `dev`
extra and in `web/requirements*.txt`, rather than a hash-locked
`requirements.txt` generated by a tool like `pip-compile`. JS dev
dependencies in `package.json` are pinned to exact versions instead of
ranges, for the same reason: this is a small, infrequently-updated
toolchain, not a large transitive dependency tree where an unreviewed
range bump is a real risk.

To bump a pin: change the version, reinstall, run the full test suite plus
the relevant lint/format command above, and read that dependency's
changelog for the versions in between - don't bump multiple dependencies in
one PR. There's no scheduled cadence; bump when a CVE, a bug fix you need,
or a new Python/Node baseline requires it.

## Licensing

Everything in this repository is MIT-licensed **except**
`questions/community/`, which is GPL-3.0 (ported from `tariqm/CKAD-2026`)
and carries its own `LICENSE` file - see that directory's own `README.md`
for the rules on ported content. The two never mix:

- A question is either wholly original (MIT, lives under
  `questions/<topic>/`) or wholly community-sourced (GPL-3.0, lives under
  `questions/community/`). Never both in the same folder.
- A PR touching `questions/community/` touches **only** that directory.
- A PR touching any other question directory doesn't copy, port, or adapt
  content from `questions/community/` or any other GPL-3.0 source.

The PR template's licensing-boundary checklist covers this - fill it in
honestly, not just as a formality.

See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for the full
inventory of vendored manifests, embedded binaries, and dependencies this
project includes, each with its license and source - update it when you
add a new runtime or build-time dependency.

## Issue labels

| Label | Applied by | Meaning |
| --- | --- | --- |
| `bug` | Bug report issue form | Something is broken or incorrect. |
| `new-question` | New question proposal issue form | A proposal for new practice-bank content. |
| `documentation` | Documentation issue form | README/CONTRIBUTING/other docs are missing, unclear, or wrong. |

General questions and discussion don't get a label - they go to
[Discussions](../../discussions) instead of an issue (see
[`SUPPORT.md`](SUPPORT.md)). Security reports never become a public
issue at all (see [`SECURITY.md`](SECURITY.md)), so there's no public
`security` label either.

## Governance, support, and security

- [`GOVERNANCE.md`](GOVERNANCE.md) - how decisions get made.
- [`SUPPORT.md`](SUPPORT.md) - where to ask a question vs. file an issue.
- [`SECURITY.md`](SECURITY.md) - how to report a vulnerability privately.

## Code of conduct

Participation in this project is governed by [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md)
(Contributor Covenant).
