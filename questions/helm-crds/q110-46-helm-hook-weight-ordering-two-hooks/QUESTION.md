# q110-46-helm-hook-weight-ordering-two-hooks: Fix two pre-install hooks running in the wrong order

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-46-helm-hook-weight-ordering-two-hooks`

`setup.sh` staged a local Helm chart named `seeder` on disk at
`questions/helm-crds/q110-46-helm-hook-weight-ordering-two-hooks/chart` (relative to the
`practice-bank/` directory), with **two** `pre-install` hook Jobs sharing a `hostPath` volume:

- `{{ .Release.Name }}-seed-data` writes a marker file to the shared volume
- `{{ .Release.Name }}-verify-data` checks that the marker file exists, failing if it doesn't

Helm runs same-phase hooks in ascending `helm.sh/hook-weight` order (lower numbers first). The
chart currently sets `seed-data`'s weight to `10` and `verify-data`'s weight to `5` - the
**opposite** of what they need - so `verify-data` runs first, before the marker file exists, and
fails. `helm install` therefore fails outright with no release created.

Fix the two Jobs' `helm.sh/hook-weight` annotations on disk so `seed-data` runs before
`verify-data` (swap the values: `seed-data` should be `5`, `verify-data` should be `10`), without
changing anything else about either Job. Then install the chart into namespace
`q110-46-helm-hook-weight-ordering-two-hooks` under release name `demo`.

## Hint

Search kubernetes.io/docs for **"helm hook weights"** - the Helm Hooks documentation explains
that `helm.sh/hook-weight` (a string-encoded integer, default `"0"`) breaks ties between
multiple hooks of the same type, executed in ascending order - the only way to control ordering
when one hook's output is needed by another in the same phase.
