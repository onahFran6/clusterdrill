# q110-19: Converge a release that may not exist yet

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-19-helm-upgrade-install-idempotent`

A local Helm chart named `toggle` is staged at
`$HOME/practice-work/q110-19-helm-upgrade-install-idempotent/chart`. The chart's
`values.yaml` sets `featureFlag: "off"`, and its
templates render a Deployment whose container has an env var `FEATURE_FLAG` sourced from
`.Values.featureFlag`, plus a ConfigMap named `{{ .Release.Name }}-toggle-cm` whose
`data.flag` carries the same value. No Helm release has been installed yet.

Using a single Helm command that works whether or not the release already exists, converge a
release named `flags` from this chart with `featureFlag` set to `on`. Do not run separate
`helm install` and `helm upgrade` commands.

## Hint

Search kubernetes.io/docs for **"helm upgrade --install"** - the Helm upgrade command
reference documents the `--install` flag, which makes `helm upgrade` create the release on
its first run and upgrade it on every run after that. Pass the override with `--set`.
