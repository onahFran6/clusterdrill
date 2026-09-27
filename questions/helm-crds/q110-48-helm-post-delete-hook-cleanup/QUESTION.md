# q110-48-helm-post-delete-hook-cleanup: Fix a post-delete hook so it actually runs cleanup on uninstall

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-48-helm-post-delete-hook-cleanup`

A local Helm chart named `archiver` is on disk at
`questions/helm-crds/q110-48-helm-post-delete-hook-cleanup/chart` (relative to `practice-bank/`).
Release `demo` is already installed in this namespace; Deployment `demo-archiver` is running.
The chart has a `post-delete` hook Job (`{{ .Release.Name }}-cleanup`) that is meant to run on
uninstall, but that hook currently does not succeed.

Fix the hook Job's command on disk so it exits successfully. Keep the `helm.sh/hook` annotation,
and do not leave duplicate files under `templates/`. Refresh the release's stored manifest with
`helm upgrade demo` against the fixed chart, **then** uninstall release `demo`. When done,
`demo-archiver` must be gone, and Job `demo-cleanup` must still exist with
`status.succeeded: 1`.

## Hint

Search kubernetes.io/docs for **"helm hooks" "post-delete"** - the Helm Hooks documentation
lists `post-delete` as firing after all of a release's other resources have been deleted, and
notes that hook resources are left in the cluster after they run unless a
`helm.sh/hook-delete-policy` is set to clean them up. A release's hook definitions are part of
its stored manifest, refreshed only by an actual `helm upgrade`, not by editing files on disk.
