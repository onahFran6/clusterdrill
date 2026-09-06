# Third-party notices

This file inventories everything in this repository, and everything the
published `clusterdrill` Docker image bundles at build time, that
originates outside this project - what it is, its license, and where it
comes from. It exists so a downstream user or auditor can confirm the
license terms of everything they're receiving without reverse-engineering
the build.

This project's own first-party code (everything not listed below) is
MIT-licensed - see [`LICENSE`](LICENSE).

## Question content

| What | License | Source | Notes |
| --- | --- | --- | --- |
| `questions/<topic>/` (every topic except `community`) | MIT | Written for this project | Task shapes and domains are sourced from the public [CNCF CKAD curriculum](https://github.com/cncf/curriculum) and [kubernetes.io/docs](https://kubernetes.io/docs/home/), never from recall of a real exam attempt - see `CONTRIBUTING.md`'s "The one hard content rule". |
| `questions/community/` | GPL-3.0 | Ported from [`tariqm/CKAD-2026`](https://github.com/tariqm/CKAD-2026) | **Excluded from the v1 primary app export** (see `tools/open-source-export/policy/clusterdrill.yaml`'s deny rule) pending a separate approved GPL content-pack distribution design - not present in the exported `clusterdrill` repository. Carries its own `LICENSE` file; see that directory's `README.md`. |

## Vendored Kubernetes manifests

| What | License | Source | Notes |
| --- | --- | --- | --- |
| `clusterdrill/manifests/local-path-provisioner.yaml` | Apache-2.0 | [`rancher/local-path-provisioner`](https://github.com/rancher/local-path-provisioner) `deploy/local-path-storage.yaml` at tag `v0.0.37` | Verified against the upstream tag's own `LICENSE` file (no `NOTICE` file exists upstream to reproduce). Vendored verbatim except container image references pinned to immutable digests - see the file's own header comment for the full rationale. |

## Binaries embedded in the published Docker image

Downloaded and copied into the image at build time (`Dockerfile`), not
just referenced - these are actually redistributed as part of the
published `clusterdrill` image.

| What | License | Source | Pinned version |
| --- | --- | --- | --- |
| `kubectl` | Apache-2.0 | [`kubernetes/kubernetes`](https://github.com/kubernetes/kubernetes) | `KUBECTL_VERSION` build arg, currently `v1.33.9` |
| `ttyd` | MIT | [`tsl0922/ttyd`](https://github.com/tsl0922/ttyd) | `TTYD_VERSION` build arg, currently `1.7.7` |

## Container base image and OS packages

The published image is built `FROM python:3.12-slim` (Debian-based) plus
`apt-get install ca-certificates curl tmux` (see `Dockerfile`, and
`.hadolint.yaml` for why those packages are deliberately left unpinned).
Every OS package's own license is documented inside the image itself
under `/usr/share/doc/<package>/copyright`, the standard Debian location -
this file does not re-enumerate the transitive package set of a stock
Debian base image, consistent with common practice for containerized
applications.

## Python runtime dependencies

Everything in `web/requirements.txt` (the `web/` app - what actually runs
inside the published Docker image) and `pyproject.toml`'s `dependencies`
(the thin `clusterdrill` pip package - the CLI, not the web app):

| Package | License |
| --- | --- |
| `fastapi` | MIT |
| `uvicorn` | BSD-3-Clause |
| `jinja2` | BSD-3-Clause |
| `markdown` | BSD-3-Clause |
| `pyyaml` | MIT |
| `python-multipart` | Apache-2.0 |
| `itsdangerous` | BSD-3-Clause |
| `httpx` | BSD-3-Clause |
| `websockets` | BSD-3-Clause |

## Runtime browser dependency (not vendored - loaded from a CDN)

| What | License | Source |
| --- | --- | --- |
| `mermaid` | MIT | Loaded from `cdn.jsdelivr.net` by `web/templates/question.html` at page-view time; never bundled into this repository or the Docker image. |

## Development-only tooling (never distributed - not in the pip package, the Docker image, or any release artifact)

| Package | License |
| --- | --- |
| `pytest`, `pytest-asyncio` | MIT / Apache-2.0 |
| `ruff` | MIT |
| `yamllint` | GPL-3.0-or-later |
| `eslint`, `markdownlint-cli`, `globals` (npm) | MIT |
| ShellCheck, hadolint, gitleaks (external tools, not installed via this repo's dependency files - see `CONTRIBUTING.md`) | GPL-3.0 / GPL-3.0 / MIT |

None of these ship in any distributed artifact (the pip package, the
Docker image, or a future Helm chart) - they run only on a contributor's
own machine or in CI, so their licenses (including yamllint's and
ShellCheck's copyleft terms) impose no obligation on this project or its
users, the same way compiling code with a GPL-licensed compiler doesn't
make the compiled program GPL.

## Helm chart dependencies

`clusterdrill/helm/clusterdrill/` is an original chart with no
vendored templates or subcharts - it renders the same MIT-licensed
resources `clusterdrill/manifests/local-appliance.yaml` does, packaging
them differently. It has no third-party dependency of its own to
declare here; the container image it deploys is the same one this
document's own container-image sections already cover.

## `clusterdrill-lab` dependencies

Not applicable here - `clusterdrill-lab` is a separate repository with its
own dependency inventory. This section belongs there, not here.
