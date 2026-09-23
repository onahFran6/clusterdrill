# q110-52: Install from an exact, pinned chart version - not whatever's newest

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-52-helm-install-pinned-version-new-namespace`

`setup.sh` staged two packaged versions of a local chart named `cache` at
`questions/helm-crds/q110-52-helm-install-pinned-version-new-namespace/chart-pkgs/`
(relative to the repo root):

- `cache-1.0.0.tgz` - `values.yaml` sets `image: redis:7.2-alpine`
- `cache-2.0.0.tgz` - `values.yaml` sets `image: redis:7.4-alpine`

Neither package has been installed yet. A teammate always just runs `helm install` against
"the chart" and gets whichever package they happen to have on disk - for this release, the
staging team needs **exactly** version `1.0.0`, not whatever looks newest or most recently
built.

Install a release named `cache01` into namespace
`q110-52-helm-install-pinned-version-new-namespace` **from the `1.0.0` package specifically**
(not `2.0.0`), so the running Deployment ends up on `redis:7.2-alpine`.

## Hint

Search kubernetes.io/docs or helm.sh/docs for **"helm install"** - the command reference
covers installing directly from a local chart archive (`.tgz`) instead of a chart directory
or a repository name.
