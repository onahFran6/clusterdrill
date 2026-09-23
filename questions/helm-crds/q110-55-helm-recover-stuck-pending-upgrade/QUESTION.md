# q110-55: Recover a release wedged in pending-upgrade, then prove it accepts a normal upgrade again

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-55-helm-recover-stuck-pending-upgrade`

A CI runner lost its connection mid-upgrade against release `stuck` (chart `stuckapp`) in
namespace `q110-55-helm-recover-stuck-pending-upgrade`. `helm history stuck` shows revision 1
`deployed` and revision 2 `pending-upgrade` - nothing is actually running that upgrade
anymore, but the release is wedged: a fresh `helm upgrade` against it fails immediately with
an error about another operation already being in progress.

Recover the release in two steps:

1. Clear the stuck lock **without discarding revision 2 from the release's history** - when
   you're done, `helm history stuck` must still list revision 2 with its `pending-upgrade`
   status intact, exactly as evidence of what happened.
2. Prove the release genuinely accepts normal operations again by performing one more real
   upgrade: move the release to image `nginx:1.27-alpine`, and have it land `deployed`.

## Hint

Search helm.sh/docs for **"helm rollback"** - a release stuck mid-upgrade can be pointed back
at its last good revision the same way a bad deploy is undone, and unlike editing the
release's storage by hand, it doesn't erase any revision history in the process.
