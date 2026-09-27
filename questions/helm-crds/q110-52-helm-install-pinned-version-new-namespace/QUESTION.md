# q110-52-helm-install-pinned-version-new-namespace: Install from an exact, pinned chart version - not whatever's newest

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-52-helm-install-pinned-version-new-namespace`

Two packaged versions of a local chart named `cache` are on disk at
`questions/helm-crds/q110-52-helm-install-pinned-version-new-namespace/chart-pkgs/` (relative to
`practice-bank/`):

- `cache-1.0.0.tgz` - defaults to `image: redis:7.2-alpine`
- `cache-2.0.0.tgz` - defaults to `image: redis:7.4-alpine`

Neither package is installed yet. Install a release named `cache01` into this namespace from the
`1.0.0` package specifically (not `2.0.0`), so the running Deployment uses `redis:7.2-alpine`.

## Hint

Search kubernetes.io/docs or helm.sh/docs for **"helm install"** - the command reference
covers installing directly from a local chart archive (`.tgz`) instead of a chart directory
or a repository name.
