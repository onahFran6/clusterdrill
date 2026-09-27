# q110-46-helm-hook-weight-ordering-two-hooks: Fix two pre-install hooks running in the wrong order

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-46-helm-hook-weight-ordering-two-hooks`

A local Helm chart named `seeder` is on disk at
`questions/helm-crds/q110-46-helm-hook-weight-ordering-two-hooks/chart` (relative to
`practice-bank/`), with two `pre-install` hook Jobs that share a `hostPath` volume:

- `{{ .Release.Name }}-seed-data` writes a marker file to the shared volume
- `{{ .Release.Name }}-verify-data` checks that the marker file exists, failing if it doesn't

An install attempt fails because the verify hook runs before the seed hook has written the
marker.

Fix the Jobs' `helm.sh/hook-weight` annotations on disk so `seed-data` runs before
`verify-data`, without changing anything else about either Job. Then install the chart into this
namespace as release `demo`.

## Hint

Search kubernetes.io/docs for **"helm hook weights"** - the Helm Hooks documentation explains
that `helm.sh/hook-weight` (a string-encoded integer, default `"0"`) breaks ties between
multiple hooks of the same type, executed in ascending order - the only way to control ordering
when one hook's output is needed by another in the same phase.
