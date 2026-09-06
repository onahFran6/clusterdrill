# q110-04: Roll back a broken release to its previous revision

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-04-helm-rollback-release`

`setup.sh` installed a Helm release named `svc` (chart `api`) into namespace
`q110-04-helm-rollback-release`, then upgraded it to revision 2 with a bad image tag that does
not exist. The Deployment `svc-api` is currently not available because of this broken upgrade.

Roll the `svc` release back to its last working revision so `svc-api` is available again
running `nginx:1.25-alpine`.

## Hint

Search kubernetes.io/docs for **"helm rollback"** - the Helm rollback command reference shows
how to revert a release to a previous revision and how `helm history` lists what's available
to roll back to.

