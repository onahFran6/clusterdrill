# q110-55-helm-recover-stuck-pending-upgrade: Recover a release wedged in pending-upgrade, then prove it accepts a normal upgrade again

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-55-helm-recover-stuck-pending-upgrade`

Release `stuck` (chart `stuckapp`) in this namespace was left mid-upgrade. `helm history stuck`
shows revision 1 `deployed` and revision 2 `pending-upgrade`. A fresh `helm upgrade` fails with
an error about another operation already in progress.

Recover the release in two steps:

1. Clear the stuck lock **without discarding revision 2 from history** - when done,
   `helm history stuck` must still list revision 2 with status `pending-upgrade`.
2. Prove normal operations work again: upgrade the release to image `nginx:1.27-alpine` and
   leave it `deployed`.

## Hint

Search helm.sh/docs for **"helm rollback"** - a release stuck mid-upgrade can be pointed back
at its last good revision the same way a bad deploy is undone, and unlike editing the
release's storage by hand, it doesn't erase any revision history in the process.
