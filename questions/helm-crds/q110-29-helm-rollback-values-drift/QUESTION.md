# q110-29-helm-rollback-values-drift: Roll back a release whose values changed across three revisions to a specific older revision

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-29-helm-rollback-values-drift`

A Helm release named `app` (chart `configurable`) is installed in this namespace. It renders
Deployment `app-configurable` (env `APP_MODE` from `.Values.mode`) and ConfigMap
`app-configurable-cfg` (`data.mode` mirrors the same value).

Release history:

- Revision 1: `mode=stable`
- Revision 2: `mode=canary`
- Revision 3 (current): `mode=broken-experimental`

Both the Deployment's `APP_MODE` and the ConfigMap's `data.mode` currently read
`broken-experimental`.

Roll the `app` release back to revision `1` specifically (not merely the previous revision)
so `mode` is `stable` again in both objects.

## Hint

Search kubernetes.io/docs for **"helm rollback"** - `helm rollback RELEASE [REVISION]` takes an
explicit revision number; `helm history` lists available revisions. A bare rollback without a
revision number lands on the previous revision (here revision 2), which is not the target.
