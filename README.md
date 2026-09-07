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
git clone <this-repository>
cd <this-repository>

# Installs the clusterdrill CLI from this checkout (no PyPI package
# published yet - see Release policy below).
pipx install ./practice-bank        # or: pip install ./practice-bank

clusterdrill local doctor           # checks prerequisites, changes nothing
clusterdrill local init             # creates the clusterdrill Minikube profile

# Build the appliance image from this exact checkout, so what you install
# matches the source you have (see Release policy for why this is the
# recommended path today, not the resolve-a-published-image default).
docker build --platform linux/arm64 --tag clusterdrill:dev practice-bank
minikube image load --profile clusterdrill clusterdrill:dev

clusterdrill local install --image clusterdrill:dev
clusterdrill local smoke-test       # verifies the health and login paths
clusterdrill local url              # opens/prints the local service URL
```

`local url` prints the appliance's URL and keeps the connection open in
that terminal (Ctrl-C when done) - open the printed URL in your browser.
If `local install` printed a password, log in with username `admin` and
that password; with `--no-password`, the URL opens straight to the topic
list, no login screen at all.

Swap `linux/arm64` for `linux/amd64` on an Intel/AMD machine. `local doctor`
is safe to run at any time and never changes anything - it fails loudly (in
under a second) if a prerequisite is wrong, so it's the first thing to run
after `git clone` and the first thing to reach for when something later
fails.

`local install` prints a generated local login password unless
`--no-password` (a localhost-only drill with no login screen) or
`--password <value>` is given. Save the printed password now - see
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

**Forgot the password, or need to reset it?** There is no separate
"forgot password" flow - re-run `local install` with an explicit
`--password <new-value>` (or `--no-password` to disable the gate
entirely). It's safe to re-run against an already-installed appliance: it
reuses the existing login password unless you override it, and only
restarts the `clusterdrill-web` Deployment, not the whole cluster.

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
deploys the exact same appliance via the chart at `clusterdrill/helm/clusterdrill/`
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

### Recommended: the Helm chart, standalone

The chart at `clusterdrill/helm/clusterdrill/` is cluster-agnostic by
design - it's what `clusterdrill local install --installer=helm` itself
runs, just without the Minikube-profile requirement:

```sh
kubectl create namespace clusterdrill-system
kubectl -n clusterdrill-system create secret generic clusterdrill-web-auth \
  --from-literal=password="$(openssl rand -base64 24 | tr -d '=+/')"

helm install clusterdrill clusterdrill/helm/clusterdrill \
  --namespace clusterdrill-system \
  --set image.repository=docker.io/w00dson/clusterdrill \
  --set image.digest=sha256:<the-released-digest> \
  --set auth.existingSecretName=clusterdrill-web-auth
```

Its Service is a `NodePort` on 8000, so once installed you reach it
directly, no CLI tunnel needed:

```sh
kubectl get svc -n clusterdrill-system clusterdrill   # find the NodePort
# then browse http://<any-node-ip>:<the-nodeport>
# or, if node IPs aren't directly reachable (a typical managed/cloud cluster):
kubectl -n clusterdrill-system port-forward svc/clusterdrill 8000:8000
```

Remove it with `helm uninstall clusterdrill --namespace clusterdrill-system`.
See [`clusterdrill/helm/clusterdrill/README.md`](clusterdrill/helm/clusterdrill/README.md)
for the full picture: what's fixed vs. configurable, and `helm upgrade`.

### Fallback: the raw manifest, applied by hand

`clusterdrill/manifests/local-appliance.yaml` is also cluster-agnostic, but
it's a template with three placeholders the CLI normally fills in for you
(`${CLUSTERDRILL_IMAGE}`, `${CLUSTERDRILL_PASSWORD}`, `${CLUSTERDRILL_VERSION}`),
and there's no CLI command to render it outside the Minikube flow, so
substitute them yourself:

```sh
sed -e "s|\${CLUSTERDRILL_IMAGE}|docker.io/w00dson/clusterdrill@sha256:<the-released-digest>|" \
    -e "s|\${CLUSTERDRILL_PASSWORD}|$(openssl rand -base64 24 | tr -d '=+/')|" \
    -e "s|\${CLUSTERDRILL_VERSION}|dev|" \
    clusterdrill/manifests/local-appliance.yaml | kubectl apply -f -
```

Unlike the Helm chart, this manifest's Service is `ClusterIP` (it's designed
around `clusterdrill local url`'s tunnel, which only exists for the Minikube
path), so reach it with `kubectl -n clusterdrill-system port-forward
svc/clusterdrill 8000:8000` instead. This path also isn't exercised
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
  (see `practice-bank/docs/adr/0001-naming-standard.md`), so state uses
  the core ConfigMap/Secret API instead of a custom type.
- **Terminal**: an embedded `ttyd` + `tmux` terminal, reverse-proxied
  through the app's own routes (never exposed on its own port), giving a
  real shell into the practice cluster from the browser.
- **Accounts**: optional. With no `CLUSTERDRILL_PASSWORD` set, the app runs
  single-user with no login screen at all - the default for local
  practice. Setting it turns on a password gate and, on first login,
  creates an admin-provisioned account model (see
  [Security limits](#security-limits)).

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
  (5 attempts / 15 minutes).
- **Classroom/multi-user mode is experimental**, gated behind its own
  explicit opt-in, and still only supported on a single dedicated
  disposable cluster - it is per-account isolation (separate namespaces,
  quotas, and RBAC-restricted terminal kubeconfigs), not safe multi-tenant
  isolation for an untrusted or production-adjacent cluster.
- **A human security review of the full RBAC contract is still
  outstanding** - `clusterdrill/tests/test_manifest.py`'s static checks
  (no cluster-admin binding, no wildcard API group, no directly-exposed
  terminal Service) guard the shape of the manifest going forward, but
  they don't replace that review. This applies equally to the optional
  Helm chart (`clusterdrill/helm/clusterdrill/`) - `test_helm_chart.py`
  proves it renders byte-for-byte the same RBAC rules as the manifest,
  so the same outstanding review covers both install paths at once, not
  a second, separate review per path.

## Troubleshooting

Run `clusterdrill local doctor` first for anything below - most of these
show up directly in its output with a specific fix.

| Symptom | Likely cause | Fix |
| --- | --- | --- |
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

Once a real release matching current source exists, the documented flow
will be:

```sh
pipx install clusterdrill==<version>
clusterdrill local doctor
clusterdrill local init
clusterdrill local install          # no --image needed
clusterdrill local url
```

`local install` resolves its own image automatically from the installed
package version, pairing each published version with an immutable,
digest-pinned image reference recorded in the package's own
`release_manifest.json` (see `clusterdrill/release.py`) - installing a
version will always deploy the exact image built and tested for it. To
upgrade, `pipx upgrade clusterdrill` (or
`pipx install clusterdrill==<newer-version> --force`), then re-run
`clusterdrill local install` to roll the running appliance forward.

No dedicated Helm chart exists yet; raw manifests
(`clusterdrill/manifests/local-appliance.yaml`, rendered by the CLI) are
the only supported install path today.

## Layout

```text
practice-bank/
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
