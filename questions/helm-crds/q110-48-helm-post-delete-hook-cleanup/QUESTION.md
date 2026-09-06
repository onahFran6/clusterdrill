# q110-48-helm-post-delete-hook-cleanup: Fix a post-delete hook so it actually runs cleanup on uninstall

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-48-helm-post-delete-hook-cleanup`

`setup.sh` staged a local Helm chart named `archiver` on disk at
`questions/helm-crds/q110-48-helm-post-delete-hook-cleanup/chart` (relative to the
`practice-bank/` directory) and installed it as release `demo` into namespace
`q110-48-helm-post-delete-hook-cleanup`. The chart's Deployment `demo-archiver` is running. It
also has a `post-delete` hook Job (`{{ .Release.Name }}-cleanup`) meant to run archival cleanup
when the release is uninstalled - but its command deliberately exits `1` right now, so if you ran
`helm uninstall` against the chart as-is, the hook would fail (though `helm uninstall` still
removes the release's other resources regardless of hook failure - unlike an install, an
uninstall isn't blocked by a failing hook).

Fix the hook Job's command on disk so it exits `0` instead (without leaving a stray backup copy
of the file in `templates/` - Helm renders every file there regardless of extension, and without
changing the `helm.sh/hook` annotation).

Editing the chart file alone is not enough: `helm uninstall` runs hooks from the manifest
**already stored** with the release at its last install/upgrade, not from whatever is currently
on disk - so uninstalling right now would still run the old, broken hook. `helm upgrade demo
<chart>` first, to refresh the release's stored manifest with your fix, **then** uninstall
release `demo`. Afterward, `demo-archiver` must be gone, but the `demo-cleanup` hook Job must
still exist in the namespace (post-delete hooks are not auto-deleted after they run, unlike hooks
using `hook-delete-policy: before-hook-creation`) and show `status.succeeded: 1`.

## Hint

Search kubernetes.io/docs for **"helm hooks" "post-delete"** - the Helm Hooks documentation
lists `post-delete` as firing after all of a release's other resources have been deleted, and
notes that hook resources are left in the cluster after they run unless a
`helm.sh/hook-delete-policy` is set to clean them up. A release's hook definitions are part of
its stored manifest, refreshed only by an actual `helm upgrade`, not by editing files on disk.
