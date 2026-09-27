# q110-39-helm-broken-posthook-fix: Fix a failing post-install hook on a release that already exists

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-39-helm-broken-posthook-fix`

A local Helm chart named `notifier` is on disk at
`questions/helm-crds/q110-39-helm-broken-posthook-fix/chart` (relative to `practice-bank/`).
An install of release `demo` left the release in `failed` status: Deployment `demo-notifier` is
Running, but the chart's `post-install` hook Job `demo-notifier-posthook` did not succeed.

Fix the hook Job's command in the chart on disk so the Job exits successfully. Keep the
`helm.sh/hook` and `helm.sh/hook-delete-policy` annotations, and do not leave duplicate files
under `templates/`. Uninstall the failed release, then install fresh from the fixed chart as
`demo` again. When done, release `demo` must be `deployed`, `demo-notifier` must have 1
available replica, and Job `demo-notifier-posthook` must have succeeded.

## Hint

Search kubernetes.io/docs for **"helm hooks"** - the Helm Hooks documentation lists which hook
types fire on which command (`pre-install`/`post-install` only on `helm install`,
`pre-upgrade`/`post-upgrade` only on `helm upgrade`), and explains that a release which fails
partway through is left in a `failed` state rather than rolled back automatically, unless
`--atomic` was used.
