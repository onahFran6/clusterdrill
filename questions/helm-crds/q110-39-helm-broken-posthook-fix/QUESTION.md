# q110-39-helm-broken-posthook-fix: Fix a failing post-install hook on a release that already exists

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-39-helm-broken-posthook-fix`

`setup.sh` staged a local Helm chart named `notifier` on disk at
`questions/helm-crds/q110-39-helm-broken-posthook-fix/chart` (relative to the `practice-bank/`
directory) and attempted `helm install demo`. The chart's Deployment applied successfully, but
its `post-install` hook Job (`{{ .Release.Name }}-notifier-posthook`) exits `1` on purpose, so
the install as a whole failed - `helm status demo` now reports the release as `failed`, even
though the Deployment `demo-notifier` is genuinely `Running` in the cluster.

Fix the hook Job's command in the chart file on disk so it exits `0` instead (edit the file
directly - do not leave a stray backup copy of it sitting in `templates/`, since Helm renders
**every** file under `templates/` as a manifest regardless of its extension, and a leftover
`.bak` copy of the broken Job would apply right alongside the fixed one), without changing the
`helm.sh/hook`/`helm.sh/hook-delete-policy` annotations.

`post-install` hooks only run during `helm install`, never during `helm upgrade` - so upgrading
the existing failed release will **not** re-run the hook at all. Uninstall the failed release
first, then install fresh from the fixed chart under the same release name, `demo`.

## Hint

Search kubernetes.io/docs for **"helm hooks"** - the Helm Hooks documentation lists which hook
types fire on which command (`pre-install`/`post-install` only on `helm install`,
`pre-upgrade`/`post-upgrade` only on `helm upgrade`), and explains that a release which fails
partway through is left in a `failed` state rather than rolled back automatically, unless
`--atomic` was used.
