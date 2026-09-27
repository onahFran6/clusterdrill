# q110-04: Restore a broken Helm release

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-04-helm-rollback-release`

A Helm release named `svc` (chart `api`) is installed in namespace
`q110-04-helm-rollback-release`. After a bad upgrade, Deployment `svc-api` is not available.

Restore the `svc` release so `svc-api` is available again running `nginx:1.25-alpine`.

## Hint

Search kubernetes.io/docs for **"helm rollback"** - the Helm rollback command reference shows
how to revert a release to a previous revision and how `helm history` lists what's available
to roll back to. Use history to find the last working revision before the bad upgrade.
