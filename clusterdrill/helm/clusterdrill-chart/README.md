# clusterdrill Helm chart

An optional, alternative install path for the ClusterDrill appliance -
the raw manifests the `clusterdrill` CLI applies directly
(`clusterdrill/manifests/local-appliance.yaml`) remain the primary,
baseline path. This chart is exactly the same appliance, packaged for
operators who prefer a Helm-managed release.

## Scope

**Not a generic deployment path.** This chart installs a single-instance,
dedicated appliance into its own cluster environment (a disposable
Minikube profile, or an equivalent dedicated cluster) - it is not
designed for, and must not be installed into, a shared, business,
classroom, or production cluster. See the practice-bank repository's own
README "Security limits" section for the full reasoning.

## What this chart does NOT let you configure

Unlike most charts, several things are deliberately fixed, not
values-driven:

- **RBAC rules.** The ClusterRole's rules are hardcoded in
  `templates/clusterrole.yaml`, byte-for-byte matching
  `clusterdrill/manifests/local-appliance.yaml`'s own ClusterRole (see
  that file's comment for the full derivation). There is no
  `rbac.rules` values key - adding one would let a values file grant
  broader access than the already-reviewed contract, which is exactly
  what this chart exists to prevent.
- **Pod security context.** Fixed non-root UID/GID 10001, a read-only
  root filesystem, and `RuntimeDefault` seccomp - not configurable.
- **Networking shape.** Exactly one `NodePort` Service on port 8000 for
  the web app. No Ingress, no `LoadBalancer`, no second Service for the
  embedded terminal (ttyd) - it is only ever reachable proxied through
  the web app's own authenticated routes.
- **Password handling.** The chart never generates, accepts, or renders
  a password value - not as a values.yaml default, not via `--set`, not
  anywhere. `auth.existingSecretName` only ever *references* a Secret
  (with a `password` key) that must already exist in the release
  namespace before you run `helm install`/`helm upgrade`. Create it
  yourself, or let `clusterdrill local install --installer=helm` create
  it for you (see the practice-bank repository's own README).
- **The namespace.** Unlike the raw manifest, this chart does not define
  its own `Namespace` resource - create it yourself (or pass
  `--create-namespace` to `helm install`) before installing. This isn't
  a style choice: Helm refuses to "adopt" a namespace you created outside
  Helm into a release unless it already carries Helm's own tracking
  annotations, which a plain `kubectl create namespace` never adds -
  found via a real live install attempt, not a design guess.

## What you do configure

- `image.repository` / `image.digest` - the published image, by
  immutable digest only. A mutable tag (including `latest`) is rejected
  by `values.schema.json`'s pattern validation.
- `auth.existingSecretName` - the name of the pre-existing password
  Secret described above.

## Install

Once a version has shipped through `.github/workflows/release-image.yml`
(see the practice-bank repository's own README "Release policy" section),
this chart is published as an OCI artifact with that release's image
already baked in as the default - no `--set image.*` flags needed:

```sh
# 1. Create the namespace and password Secret first (or let the CLI do
#    both steps for you - see below).
kubectl create namespace clusterdrill-system
kubectl -n clusterdrill-system create secret generic clusterdrill-web-auth \
  --from-literal=password="$(openssl rand -base64 24 | tr -d '=+/')"

# 2. Install the published chart.
helm install clusterdrill oci://registry-1.docker.io/w00dson/clusterdrill-chart \
  --version <version> \
  --namespace clusterdrill-system \
  --set auth.existingSecretName=clusterdrill-web-auth
```

Or, more simply, from the CLI once it preflights Helm and your dedicated
profile:

```sh
clusterdrill local install --installer=helm
```

### Developing this chart itself

Working from a local checkout (this chart hasn't been rebuilt/published
yet, or you're testing a chart-template change) needs the image pinned
by hand instead:

```sh
helm install clusterdrill . \
  --namespace clusterdrill-system \
  --set image.repository=docker.io/w00dson/clusterdrill \
  --set image.digest=sha256:<the-digest-to-test> \
  --set auth.existingSecretName=clusterdrill-web-auth
```

## Verifying this chart matches the raw manifest

`clusterdrill/tests/test_helm_chart.py` renders this chart with
representative values and asserts its output is RBAC- and shape-
equivalent to `clusterdrill/manifests/local-appliance.yaml` (same
resource kinds/names, identical ClusterRole rules, exactly one Service,
no cluster-admin binding, no wildcard apiGroup) - the same static
guarantees `clusterdrill/tests/test_manifest.py` already gives the raw
manifest, applied to this chart's rendered output instead.

**These tests guard the shape of the chart going forward. They do not
replace a human security review of the RBAC contract itself** - see
practice-bank's own README "Security limits" section, which already
documents that the underlying RBAC contract has this same outstanding
review regardless of which install path renders it.

## Upgrade and uninstall

```sh
helm upgrade clusterdrill oci://registry-1.docker.io/w00dson/clusterdrill-chart \
  --version <newer-version> --namespace clusterdrill-system --reuse-values

helm uninstall clusterdrill --namespace clusterdrill-system
```

(Substitute `.` and `--set image.digest=sha256:<the-new-digest>` instead
if you're working from a local checkout, as in "Developing this chart
itself" above.)

`helm uninstall` removes the namespace-scoped resources this chart
created plus the cluster-scoped ClusterRole/ClusterRoleBinding - nothing
outside those and the `clusterdrill-system` namespace. It does not touch
the password Secret if you created it outside the chart yourself
(`helm install`/`upgrade` only manages resources this chart's own
templates define).
