# q110-27: Resolve a release name collision across two chart versions in one namespace

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-27-helm-release-name-collision-namespace`

`setup.sh` staged two local charts on disk, both named `engine`:

- `questions/helm-crds/q110-27-helm-release-name-collision-namespace/chart-v1` (Chart.yaml
  `version: 1.0.0`), already installed as Helm release `core` in namespace
  `q110-27-helm-release-name-collision-namespace` - currently revision 1, status `deployed`,
  with Deployment `core-engine` running `nginx:1.25-alpine`.
- `questions/helm-crds/q110-27-helm-release-name-collision-namespace/chart-v2` (Chart.yaml
  `version: 2.0.0`, same chart name `engine`), not yet used by any release. Its
  `values.yaml` still sets `image: nginx:1.25-alpine`, but its `templates/deployment.yaml`
  additionally adds a second container port `8443` and an env var `PROTOCOL=https` that the
  v1 chart's Deployment does not have.

Upgrade the existing `core` release **in place** to use chart-v2, so that revision 2 reflects
the v2 chart's Deployment shape (container port `8443` present, env `PROTOCOL=https` present).
Do **not** uninstall and reinstall the release, and do **not** install a second release - the
release name must stay `core` and the Deployment name must stay `core-engine`.

## Hint

Search kubernetes.io/docs for **"helm upgrade"** - the Helm upgrade command reference shows
how to point an existing release at a different chart (including a different chart version)
in place, advancing its revision number without touching the release name.
