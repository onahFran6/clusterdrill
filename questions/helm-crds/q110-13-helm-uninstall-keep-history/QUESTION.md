# q110-13: Uninstall a release while keeping its history

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-13-helm-uninstall-keep-history`

`setup.sh` installed a local Helm chart named `widget` (staged on disk at
`questions/helm-crds/q110-13-helm-uninstall-keep-history/chart`, relative to the
`practice-bank/` directory) as release `demo` into namespace
`q110-13-helm-uninstall-keep-history`. The chart templates a single-replica Deployment.

Uninstall the `demo` release, but retain its release history so that
`helm history demo -n q110-13-helm-uninstall-keep-history` still shows revision 1 (with status
`uninstalled`) afterward. The underlying Deployment `demo-widget` must be removed, and
`helm status demo -n q110-13-helm-uninstall-keep-history` must no longer report the release as
deployed.

## Hint

Search kubernetes.io/docs for **"helm uninstall keep-history"** - the Helm uninstall command
reference documents a flag that removes a release's resources but leaves its revision history
in place for `helm history` to still show.
