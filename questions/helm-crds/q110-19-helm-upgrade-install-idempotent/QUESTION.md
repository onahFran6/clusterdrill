# q110-19: Use upgrade --install to converge a release that may not exist yet

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-19-helm-upgrade-install-idempotent`

`setup.sh` staged a local Helm chart named `toggle` on disk at
`questions/helm-crds/q110-19-helm-upgrade-install-idempotent/chart` (relative to the
`practice-bank/` directory). The chart's `values.yaml` sets `featureFlag: "off"`, and its
templates render a Deployment whose container has an env var `FEATURE_FLAG` sourced from
`.Values.featureFlag`, plus a ConfigMap named `{{ .Release.Name }}-toggle-cm` whose
`data.flag` carries the same value. No Helm release has been installed yet - namespace
`q110-19-helm-upgrade-install-idempotent` starts with zero Helm releases.

Using a **single Helm command** that works whether or not the release already exists,
converge a release named `flags` from this chart with `featureFlag` set to `on` (via
`--set`). Do not run separate `helm install` / `helm upgrade` commands - use one command
that is safe to (re)run regardless of the release's current state.

## Hint

Search kubernetes.io/docs for **"helm upgrade --install"** - the Helm upgrade command
reference documents the `--install` flag, which makes `helm upgrade` idempotently create
the release on its first run and upgrade it on every run after that.
