# q110-29: Roll back a release whose values changed across three revisions to a specific older revision

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-29-helm-rollback-values-drift`

`setup.sh` installed a Helm release named `app` (chart `configurable`) into namespace
`q110-29-helm-rollback-values-drift`. The chart renders a Deployment `app-configurable` whose
container sets env var `APP_MODE` from `.Values.mode`, and a ConfigMap `app-configurable-cfg`
whose `data.mode` mirrors the same value.

The release has since been upgraded twice:

- Revision 1 (original install): `mode=stable`
- Revision 2: `mode=canary`
- Revision 3 (current live state): `mode=broken-experimental`

Both the Deployment's `APP_MODE` env var and the ConfigMap's `data.mode` currently read
`broken-experimental`.

Inspect the release history with `helm history app -n q110-29-helm-rollback-values-drift` and
roll the `app` release back to **revision 1 specifically** (not just "the previous revision" -
a plain `helm rollback app` with no revision number would land on revision 2/`canary`, which is
wrong) so that `mode` reverts fully to `stable` in both the Deployment and the ConfigMap.

## Hint

Search kubernetes.io/docs for **"helm rollback"** - the Helm rollback command reference shows
that `helm rollback RELEASE [REVISION]` takes an explicit revision number, and `helm history`
lists every revision available to roll back to.
