# ClusterDrill

A lab-style CKAD question bank: per-topic pools of hands-on questions, each
graded against live cluster state, run against a real Kubernetes cluster
(a local Minikube appliance, or any dedicated disposable cluster you point
it at).

- [Which install path fits you?](#which-install-path-fits-you)
- [Quick start](#quick-start)
- [Supported-cluster contract](#supported-cluster-contract)
- [Login, upgrade, and removal](#login-upgrade-and-removal)
- [Installing on a cluster you already have](#installing-on-a-cluster-you-already-have)
- [Architecture](#architecture)
- [Using your own terminal](#using-your-own-terminal)
- [Security limits](#security-limits)
- [Troubleshooting](#troubleshooting)
- [Release policy](#release-policy)
- [Layout](#layout)
- [Licensing](#licensing)
- [Contributing](#contributing)

## Which install path fits you?

| Your situation | Where to go |
| --- | --- |
| No cluster yet, just want to try ClusterDrill on your own laptop | [Quick start](#quick-start) below - creates a disposable local Minikube profile for you. |
| No cluster yet, want a real disposable cluster (e.g. for a workshop or classroom, not just a local trial) | [`clusterdrill-lab`](https://github.com/onahFran6/clusterdrill-lab) - a separate repository. It uses Terraform to provision a disposable cloud VM and a bootstrap script to install Kubernetes plus a pinned ClusterDrill release on it automatically. Needs its own prerequisites (AWS credentials, Terraform >= 1.5.0) and isn't tested or maintained from this repository - see its own README. |
| You already have your own dedicated, disposable Kubernetes cluster (self-managed, kubeadm, a cloud-managed cluster, etc.) and just want to install ClusterDrill onto it | [Installing on a cluster you already have](#installing-on-a-cluster-you-already-have) - `clusterdrill local install` doesn't apply here, see why in that section. |

## Quick start

No AWS account or Terraform is required - a laptop with Python 3.11+,
Docker, Minikube, and `kubectl` installed is the only prerequisite.
Everything below runs
against a dedicated `clusterdrill` Minikube profile that never touches an
existing cluster or kubectl context.

```sh
git clone https://github.com/onahFran6/clusterdrill.git
cd clusterdrill

# Installs the clusterdrill CLI from this checkout (no PyPI package
# published yet - see Release policy below). Prefer pipx: it puts
# `clusterdrill` on PATH for you. If you only have pip, use the
# python -m form (bare `pip` is often missing on macOS) and then put
# the user scripts directory on PATH before the next commands.
pipx install .                      # preferred
# or:
# python3 -m pip install .
# export PATH="$(python3 -m site --user-base)/bin:$PATH"   # macOS/Linux user install

clusterdrill local doctor           # checks prerequisites, changes nothing
clusterdrill local init             # creates the clusterdrill Minikube profile

# Build the appliance image from this exact checkout, so what you install
# matches the source you have (see Release policy for why this is the
# recommended path today, not the resolve-a-published-image default).
docker build --platform linux/arm64 --tag clusterdrill:dev .
minikube image load --profile clusterdrill clusterdrill:dev

clusterdrill local install --image clusterdrill:dev
clusterdrill local smoke-test       # verifies the health and login paths
clusterdrill local url              # opens/prints the local service URL
```

`local url` prints the appliance's URL and keeps the connection open in
that terminal (Ctrl-C when done) - open the printed URL in your browser. By
default it opens straight to the topic list, no login screen at all; if you
installed with `--password <value>`, log in with username `admin` and that
password instead.

Swap `linux/arm64` for `linux/amd64` on an Intel/AMD machine. `local doctor`
is safe to run at any time and never changes anything - it fails loudly (in
under a second) if a prerequisite is wrong, so it's the first thing to run
after `git clone` and the first thing to reach for when something later
fails.

**No password gate by default.** `local install` only sets one if you pass
`--password <value>` - appropriate because the appliance is already a
single-trusted-operator, disposable-cluster tool with no other access
control in front of it; a login screen only matters once something else
(a tunnel, a shared machine) puts the appliance within reach of someone
else. Pass `--password <value>` before doing that - see
[Login, upgrade, and removal](#login-upgrade-and-removal) for how to
retrieve or reset it later.

## Supported-cluster contract

`clusterdrill local doctor` is this contract made executable - every line
below is a real check it runs, not just documentation that can drift from
the code:

- **Host**: macOS or Ubuntu Linux, on `arm64`/`aarch64` or `x86_64`/`amd64`.
- **Docker**: installed, running, and healthy (Docker Desktop or Docker
  Engine). `local init` reads Docker's available CPU/memory to pick sane
  Minikube resource defaults, overridable with `--cpus`/`--memory`.
- **Minikube profile**: the dedicated `clusterdrill` profile, created with
  the `docker` driver, exactly one node. `local doctor` flags a profile
  that was created some other way (a different driver, more than one
  node) and tells you to `local destroy && local init` to fix it - these
  are cluster-creation-time choices, not something `local install` can
  change on an existing profile.
- **Default StorageClass**: something must be marked as the cluster
  default, or dynamic provisioning (and every question that needs a
  PersistentVolumeClaim) fails. `local init` installs one of two pinned
  provisioners automatically - see `--storage-profile` below.
- **RBAC**: the current kubectl identity needs create access to
  namespaces, ClusterRoles/ClusterRoleBindings, ServiceAccounts, Secrets,
  Deployments, and Services in the `clusterdrill` context. `local doctor`
  checks each with a read-only `kubectl auth can-i` before `local install`
  ever attempts a real mutation.

Only the local Minikube appliance is documented and tested end to end
today. Already have a dedicated, disposable cluster that satisfies the same
contract? See [Installing on a cluster you already have](#installing-on-a-cluster-you-already-have),
which isn't validated by this project's own tests the way the Minikube flow
is, but works.

### Storage compatibility profiles

`local init` defaults to Minikube's built-in `standard` StorageClass
(`k8s.io/minikube-hostpath`, `Immediate` binding). Pass
`--storage-profile local-path` to install a pinned, digest-locked copy of
the Rancher `local-path-provisioner` instead (`rancher.io/local-path`,
`WaitForFirstConsumer` binding) - a small number of storage questions that
hardcode the `minikube` provisioner or class name are excluded under this
profile, and `local doctor` reports exactly which ones and how to switch
back. This is a cluster-creation-time choice, not a live toggle: switch
with `local destroy && local init --storage-profile local-path`.

## Login, upgrade, and removal

**Forgot an account's password?** If you're still logged in as an admin,
use the Admin page to reset another account's password - there is no
self-service "change my own password" flow yet. Re-running `local install
--password <new-value>` does **not** change an existing account's
password: it deliberately refuses (`Refusing to change it because existing
accounts retain their current password hash`) once any account exists, so
a Secret an attacker with cluster access could otherwise edit can't
silently take over a login. `--password` only takes effect the first time,
before any account exists.

**Locked out of every admin account, with no other admin to ask?** Delete
the account Secrets directly so the bootstrap admin reseeds from
`CLUSTERDRILL_PASSWORD` on the next restart - this does not lose any
profile/achievement progress, which is stored separately and keyed by the
same `admin` user id:

```sh
kubectl --context clusterdrill delete secret -n clusterdrill-system -l clusterdrill-kind=user
clusterdrill local install --password <new-value>   # restarts the Deployment, reseeds "admin"
```

**Disabling the password gate entirely**: `local install --no-password`.
Re-running `local install` is otherwise safe against an already-installed
appliance - it only restarts the `clusterdrill-web` Deployment, not the
whole cluster.

**Upgrading**: rebuild the image from an updated checkout (or resolve a
newer published release, once one exists - see
[Release policy](#release-policy)) and run `local install` again with the
new `--image`. Progress data (per-user profiles and achievements) lives in
the cluster itself, not the image, so a reinstall never loses it.

**Removing everything**: `clusterdrill local destroy` deletes only the
`clusterdrill` Minikube profile - nothing else on your machine or any
other kubectl context is touched. Add `--yes` to skip the interactive
confirmation.

**Optional Helm install path**: `clusterdrill local install --installer=helm`
deploys the exact same appliance via the chart at `clusterdrill/helm/clusterdrill-chart/`
instead of applying the raw manifest directly - both render the same
RBAC/Deployment/Service shape (`clusterdrill/tests/test_helm_chart.py`
enforces this equivalence). See that chart's own README for what it
does and does not let you configure, and for `helm upgrade`/`helm uninstall`
usage directly (without going through the CLI).

## Installing on a cluster you already have

**`clusterdrill local install` (and every other `clusterdrill local ...`
subcommand) only ever targets the dedicated `clusterdrill` Minikube
profile, and cannot be pointed at another cluster or kubectl context.** If
you already have your own dedicated, disposable Kubernetes cluster, don't
reach for the CLI at all; use one of the two paths below directly instead.

Either path needs the same access this project's own [Supported-cluster
contract](#supported-cluster-contract) requires from the Minikube profile:
create access to Namespaces, ClusterRoles/ClusterRoleBindings,
ServiceAccounts, Secrets, Deployments, and Services in your current kubectl
context.

### Getting an image to install

Both paths below need an `image.repository`/digest - **but the Helm
chart's own published defaults already cover the common case**: its
`values.yaml` ships pre-filled with each release's real repository/digest
(see [Release policy](#release-policy) for how that pipeline works), so
most readers can skip straight to
[Recommended: the Helm chart, standalone](#recommended-the-helm-chart-standalone)
below with no `--set image.*` flags at all.

Only build and push your own image if you want to test unreleased
source, or need a custom registry your cluster can pull from - unlike
the Minikube path, there's no `minikube image load` shortcut here:

```sh
docker build --platform linux/amd64 --tag <your-registry>/clusterdrill:dev .   # match your cluster's node arch
docker push <your-registry>/clusterdrill:dev
docker inspect --format='{{index .RepoDigests 0}}' <your-registry>/clusterdrill:dev
# -> <your-registry>/clusterdrill@sha256:<the digest you just pushed>
```

Use that repository and digest with the `--set image.*` overrides shown
below.

### Recommended: the Helm chart, standalone

The chart at `clusterdrill/helm/clusterdrill-chart/` is cluster-agnostic
by design - it's what `clusterdrill local install --installer=helm`
itself runs, just without the Minikube-profile requirement. It's also
published as an OCI chart, by the pipeline described in
[Release policy](#release-policy), with each release's image already
baked in as the default, so installing needs no `--set image.*` flags at
all:

```sh
kubectl create namespace clusterdrill-system
kubectl -n clusterdrill-system create secret generic clusterdrill-web-auth \
  --from-literal=password="$(openssl rand -base64 24 | tr -d '=+/')"

helm install clusterdrill oci://registry-1.docker.io/w00dson/clusterdrill-chart \
  --version <version> \
  --namespace clusterdrill-system \
  --set auth.existingSecretName=clusterdrill-web-auth
```

(`<version>` is any published release - see
`clusterdrill/release_manifest.json` or the
[GitHub Releases page](https://github.com/onahFran6/clusterdrill/releases)
for the latest. To test unreleased source instead, install from a local
checkout with `helm install clusterdrill
clusterdrill/helm/clusterdrill-chart`, adding `--set
image.repository=...`/`--set image.digest=...` to point at a self-built
image as described above.)

Its Service is `ClusterIP` by default, same as the raw manifest path -
reach it with a port-forward:

```sh
kubectl -n clusterdrill-system port-forward svc/clusterdrill 8000:8000
```

Set `--set service.type=NodePort` at install time only on a network you
already trust - this chart doesn't configure TLS termination or Secure
cookies for you either way (see [Security limits](#security-limits)).

Remove it with `helm uninstall clusterdrill --namespace clusterdrill-system`.
See [`clusterdrill/helm/clusterdrill-chart/README.md`](clusterdrill/helm/clusterdrill-chart/README.md)
for the full picture: what's fixed vs. configurable, and `helm upgrade`.

### Fallback: the raw manifest, applied by hand

`clusterdrill/manifests/local-appliance.yaml` is also cluster-agnostic, but
it's a template with four placeholders the CLI normally fills in for you
(`${CLUSTERDRILL_IMAGE}`, `${CLUSTERDRILL_PASSWORD}`, `${CLUSTERDRILL_VERSION}`, `${CLUSTERDRILL_PRACTICE_CONTEXT}`),
and there's no CLI command to render it outside the Minikube flow, so
substitute them yourself. Use any published release's digest (see
[Release policy](#release-policy)), or substitute a self-built image as
described above to test unreleased source:

```sh
sed -e "s|\${CLUSTERDRILL_IMAGE}|docker.io/w00dson/clusterdrill@sha256:<the published digest>|" \
    -e "s|\${CLUSTERDRILL_PASSWORD}|$(openssl rand -base64 24 | tr -d '=+/')|" \
    -e "s|\${CLUSTERDRILL_VERSION}|<version>|" \
    -e 's|${CLUSTERDRILL_PRACTICE_CONTEXT}||' \
    clusterdrill/manifests/local-appliance.yaml | kubectl apply -f -
```

Like the Helm chart's own default, this manifest's Service is `ClusterIP`
(it's designed around `clusterdrill local url`'s tunnel, which only exists
for the Minikube path), so reach it with `kubectl -n clusterdrill-system
port-forward svc/clusterdrill 8000:8000` instead. This path also isn't exercised
end-to-end by this project's own tests the way the Minikube flow is - prefer
the Helm chart above unless you have a specific reason not to. Remove it
with `kubectl delete -f <the-same-rendered-manifest>`.

## Architecture

See [`docs/architecture.md`](docs/architecture.md) for the deep technical
dive (request flow, module wiring, design rationale) behind the summary
below.

- **App**: a single FastAPI process (`web/app.py`), server-rendered Jinja2
  HTML plus a light sprinkle of vanilla JS - no SPA framework, no build
  step.
- **Questions**: plain folders on disk (`questions/<topic>/qNNN-slug/`),
  not a database. `setup.sh` seeds a broken/partial starting state in a
  dedicated namespace; `check.sh` grades **only live cluster state**,
  never a client-supplied "done" flag - see [Layout](#layout) for the full
  folder shape.
- **State**: per-user profile and achievement progress is stored as
  Kubernetes ConfigMaps/Secrets in the app's own `clusterdrill-system`
  namespace - "store progress as Kubernetes objects, not database rows,"
  with no separate database dependency. There is no project-owned Custom
  Resource Definition: no domain is confirmed as owned by this project yet
  (see `docs/adr/0001-naming-standard.md`), so state uses
  the core ConfigMap/Secret API instead of a custom type.
- **Terminal**: an embedded `ttyd` + `tmux` terminal, reverse-proxied
  through the app's own routes (never exposed on its own port), giving a
  real shell into the practice cluster from the browser.
- **Accounts**: optional. With no `CLUSTERDRILL_PASSWORD` set, the app runs
  single-user with no login screen at all - the default for local
  practice. Setting it turns on a password gate and, on first login,
  creates an admin-provisioned account model (see
  [Security limits](#security-limits)).

## Using your own terminal

Each question page can hide the embedded terminal and keep that choice in
this browser. Hiding it does not stop question setup, and it does not pause
an exam timer. The same page's "Use your own terminal" section shows the
runtime namespace and the workspace directory inside the application.

Seeded task files live in that application workspace
(`$HOME/practice-work/<question-id>` on the process that runs ClusterDrill).
They are not automatically present on your laptop, or in an SSH home
directory on a control-plane or worker host. For the local single-user
appliance, the page can show a `kubectl exec` command into the running web
container so a laptop terminal, or a node shell that already has API
access, sees those same files. That command uses the application identity.
It is not a restricted learner shell, and signing out of the browser does
not revoke a kubeconfig or SSH key you already have.

With the password gate on, a quiet browser is logged out and its embedded
terminals are stopped. The practice or exam attempt itself stays until you
end it, the exam deadline is graded, or the app process restarts. Sign in
again to continue an unexpired attempt or to open exam results. The Helm
chart does not set single-user mode, so it does not show that owner exec
command; the local appliance manifest does.

## Security limits

Read this before putting the appliance anywhere reachable beyond your own
machine.

- **Single dedicated, disposable cluster only.** This is not a
  multi-tenant platform and must never be pointed at a shared or
  production cluster. The appliance's own ClusterRole is scoped to the API
  groups/resources the question bank and app bootstrap actually use (not
  cluster-admin), but it still creates namespaces and cluster-scoped
  objects freely within whatever cluster it's given - only a cluster you
  are willing to have fully rearranged by practice questions is safe to
  use.
- **No telemetry from the app itself.** Nothing in this codebase phones
  home, tracks usage, or reports analytics to a third party. The browser
  does load two things over the network regardless of login state: Google
  Fonts (`fonts.googleapis.com`/`fonts.gstatic.com`) and Mermaid.js from a
  CDN, both for rendering only - no application data is sent to either.
- **The password gate is off by default.** With `CLUSTERDRILL_PASSWORD`
  unset, there is no login page and no session cookie logic runs at all -
  appropriate only when the appliance is reachable exclusively from your
  own machine or through your own SSH tunnel. Set it (or pass a password
  to `local install`) before putting the appliance behind any public
  tunnel or reverse proxy.
- **Accounts, when enabled, are admin-provisioned only** - there is no
  public sign-up route. Passwords are hashed with PBKDF2-HMAC-SHA256 (260k
  iterations, a per-user random salt); login is rate-limited per client IP
  (5 attempts / 15 minutes). That limit keys on the real TCP peer unless
  `CLUSTERDRILL_TRUSTED_PROXY_IPS` (comma-separated IPs) names a proxy
  actually in front of this app - only then are `CF-Connecting-IP`/
  `X-Forwarded-For` trusted, since otherwise any direct client could set
  those headers itself and dodge the limit entirely. Logging out, or an
  admin resetting a password, revokes that account's sessions including
  any already-open terminal connection, not just the browser cookie that
  triggered it.
- **Terminal credentials fail closed, not insecure, if a CA can't be
  resolved.** Each account's terminal authenticates with its own
  RBAC-scoped kubeconfig, never the app's own. If no certificate authority
  can be found for it, provisioning fails rather than silently falling
  back to no TLS verification - set
  `CLUSTERDRILL_ALLOW_INSECURE_KUBECONFIG=true` only if you understand and
  accept that trade-off (e.g. a deliberately TLS-disabled dev cluster).
- **Session cookies aren't marked Secure by default**, matching local
  dev/an SSH tunnel/a loopback-only proxy hop (nothing public ever sees
  that hop either way, so requiring HTTPS there would only break access
  for no protection). Set `CLUSTERDRILL_SECURE_COOKIES=true` once this
  appliance is actually served over real HTTPS (a NodePort/Ingress install
  with a TLS-terminating proxy in front).
- **There is no classroom/multi-user mode.** This appliance supports
  exactly one account (the bootstrap admin) - a security review found that
  per-account namespace/RBAC isolation alone didn't actually isolate
  learners sharing one appliance process (a shared OS user/filesystem
  still let one learner's terminal reach another's, or the application's
  own, kubeconfig). Supporting more than one person safely means a
  separate disposable cluster per person, not more accounts on this one.
- **A human security review of the full RBAC contract is still
  outstanding** - `clusterdrill/tests/test_manifest.py`'s static checks
  (no cluster-admin binding, no wildcard API group, no directly-exposed
  terminal Service) guard the shape of the manifest going forward, but
  they don't replace that review. This applies equally to the optional
  Helm chart (`clusterdrill/helm/clusterdrill-chart/`) - `test_helm_chart.py`
  proves it renders byte-for-byte the same RBAC rules as the manifest,
  so the same outstanding review covers both install paths at once, not
  a second, separate review per path.

## Troubleshooting

Run `clusterdrill local doctor` first for anything below - most of these
show up directly in its output with a specific fix.

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `zsh: command not found: clusterdrill` (or the same from bash) | CLI never installed, or a user-level `pip` install put the script somewhere not on `PATH` | From the checkout: `pipx install .`, or `python3 -m pip install .` then `export PATH="$(python3 -m site --user-base)/bin:$PATH"`. Confirm with `command -v clusterdrill`. |
| `local doctor` reports Docker not healthy | Docker Desktop/Engine isn't running | Start Docker, then re-run `local doctor`. |
| `local doctor` flags the wrong driver or node count | An existing `clusterdrill` profile was created some other way | `clusterdrill local destroy && clusterdrill local init`. |
| `local doctor` reports no default StorageClass | The profile's default provisioner was removed or never installed | `clusterdrill local destroy && clusterdrill local init` to recreate it. |
| A `can-i` check fails | The current kubectl identity lacks a needed permission | Fix cluster RBAC, or check Docker Desktop's Kubernetes access settings, then re-run `local doctor`. |
| `local install` fails with `spec.selector: ... field is immutable` | An existing Deployment predates a metadata/selector change | `kubectl --context clusterdrill delete deployment clusterdrill-web -n clusterdrill-system`, then re-run `local install`. |
| Terminal panel shows "unavailable" | `ttyd` isn't installed inside the image, or `tmux` isn't on the appliance's `PATH` | Rebuild the image; this shouldn't happen with the published/dev images as built. |
| `local smoke-test` gets a 401 on `/healthz` | An outdated image is deployed that predates the current `/healthz` public-path exemption | Rebuild from the current checkout and reinstall with `--image clusterdrill:dev` rather than relying on a possibly-stale resolved image. |

## Release policy

No `clusterdrill` package has been published to PyPI yet, so
`pipx install clusterdrill` (without a local path) does not work today.
Install from a local checkout instead - see [Quick start](#quick-start).

A container image was published once, early in this project's history,
before several naming and architecture changes landed in this source
tree - `local install` (with no `--image`) will still resolve and deploy
that specific old image automatically once the package is installed,
since it's a real, signed, tested artifact paired to a real package
version. **It does not reflect the current source tree.** Always pass
`--image clusterdrill:dev` (built from your own checkout, as in
[Quick start](#quick-start)) unless you specifically want that
historical artifact.

This repo has automated release tooling: `release-please` computes each
version and changelog from Conventional Commits merged to `main`, and
`.github/workflows/release-image.yml` builds and publishes a real
multi-arch image plus an OCI Helm chart for every version it tags - see
[`MAINTAINING.md`](MAINTAINING.md) for exactly how the two fit together.
Every version from `0.1.1` onward has gone through this pipeline for
real; the historical-image caveat above is specific to `0.1.0`, the one
manually-published exception. From `0.1.1` onward:

```sh
pipx install clusterdrill==<version>
clusterdrill local doctor
clusterdrill local init
clusterdrill local install          # no --image needed
clusterdrill local url
```

resolves and deploys that version's real, pipeline-built image
automatically. `local install` resolves its own image from the installed
package version, pairing each published version with an immutable,
digest-pinned image reference recorded in the package's own
`release_manifest.json` (see `clusterdrill/release.py`) - installing a
version will always deploy the exact image built and tested for it. To
upgrade, `pipx upgrade clusterdrill` (or
`pipx install clusterdrill==<newer-version> --force`), then re-run
`clusterdrill local install` to roll the running appliance forward.

The Helm chart at `clusterdrill/helm/clusterdrill-chart/` is also
published by the same pipeline, as an OCI chart
(`oci://registry-1.docker.io/w00dson/clusterdrill-chart`) with each
release's image already baked in as the default - see
[Installing on a cluster you already have](#installing-on-a-cluster-you-already-have)
for the install command.

## Layout

```text
clusterdrill/
  questions/
    <topic>/
      domains.fragment.yaml   # this topic's question metadata (domain, difficulty, resource kinds)
      qNNN-slug/
        QUESTION.md            # task, docs-search hint, CNCF domain + points
        setup.sh                # idempotent: creates/resets namespace qNNN, seeds resources
        check.sh                # grading criteria against live cluster state
        ANSWER.md               # reference solution + direct doc link
        diagram.mmd              # generated Mermaid diagram
    community/
      LICENSE                  # GPL-3.0 - covers only this directory
      README.md                # rules for ported content
  web/                        # the FastAPI app - see Architecture above
  clusterdrill/               # the CLI (this file's Quick start) and packaged manifests
  lib/
    grading.sh                 # resource_exists, kget, check_criterion, print_score, full_reset
    verify-question.sh         # per-question test harness (reset/unsolved=0, answer=full marks, reset=clean)
    load-domains.sh            # merges every domains.fragment.yaml into .generated/domains.yaml
    bootstrap-minikube.sh      # gets a local cluster ready for verify-question.sh runs
  tests/
    bootstrap-minikube_test.sh # self-test for bootstrap-minikube.sh against faked minikube/kubectl binaries
    e2e/                       # real browser-level end-to-end tests
  docs/
    architecture.md            # module wiring, request flow, design rationale
    adr/                       # naming and metadata-convention decision records
  .github/
    CODEOWNERS                # routes question/lib/governance changes for review
    PULL_REQUEST_TEMPLATE.md  # MIT/GPL boundary checklist
    ISSUE_TEMPLATE/           # bug report, new question proposal, docs issue, discussion/security redirects
  LICENSE                     # MIT - covers everything except questions/community/
  THIRD_PARTY_NOTICES.md      # SPDX inventory of every vendored/bundled/dependency license
  CODE_OF_CONDUCT.md          # Contributor Covenant
  GOVERNANCE.md               # single-maintainer decision model
  SECURITY.md                 # private vulnerability reporting
  SUPPORT.md                  # where to ask questions vs. file issues
  CONTRIBUTING.md             # folder shape, verify-question.sh gate, exam-content rule
```

Note: `.github/` only takes effect once this directory becomes its own
repo root - GitHub only reads PR/issue templates from the actual
repository root, not a subdirectory, so these are staged in advance
rather than live in this monorepo today.

## Licensing

- Everything in this repository is MIT-licensed, **except** `questions/community/`,
  which is GPL-3.0 (ported from `tariqm/CKAD-2026`) and carries its own `LICENSE`.
- Never mix original and ported content in the same question folder.
- See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for every third-party
  component this repository or the published Docker image includes - vendored
  manifests, embedded binaries, and runtime dependencies, each with its
  license and source.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the question-content folder
shape, the one hard content rule, and how to verify a question locally
before opening a PR.

## Trademark disclaimer

ClusterDrill is not affiliated with, endorsed by, or sponsored by the Linux Foundation or the
Cloud Native Computing Foundation. "Certified Kubernetes Application Developer" and "CKAD" are
trademarks of the Linux Foundation.
