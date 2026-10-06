# q110-27-helm-release-name-collision-namespace: Resolve a release name collision across two chart versions in one namespace

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-27-helm-release-name-collision-namespace`

Two local charts named `engine` are on disk:

- `$HOME/practice-work/q110-27-helm-release-name-collision-namespace/chart-v1` (version `1.0.0`),
  already installed as release `core` in this namespace (revision 1, status `deployed`), with
  Deployment `core-engine` running `nginx:1.25-alpine`.
- `$HOME/practice-work/q110-27-helm-release-name-collision-namespace/chart-v2` (version `2.0.0`),
  not yet used. Its Deployment template adds container port `8443` and env `PROTOCOL=https`.

Upgrade the existing `core` release in place to chart-v2 so revision 2 reflects that shape
(port `8443` and env `PROTOCOL=https` present). Do not uninstall/reinstall, and do not install
a second release - keep release name `core` and Deployment name `core-engine`.

## Hint

Search kubernetes.io/docs for **"helm upgrade"** - the Helm upgrade command reference shows
how to point an existing release at a different chart path (or chart version) in place,
advancing its revision without changing the release name.
