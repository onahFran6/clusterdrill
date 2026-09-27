# q110-54-helm-upgrade-install-atomic-rollback: Make a bad upgrade roll itself back instead of leaving the release half-broken

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-54-helm-upgrade-install-atomic-rollback`

Release `api` (chart `atomicapp`) is already installed in this namespace at revision 1,
`deployed`, running `nginx:1.25-alpine`.

With a single `helm upgrade --install` command that also works if the release were missing,
blocks until pods are ready (timeout capped at **60 seconds**, not the 5-minute default), and
automatically rolls back on failure (manual `helm rollback` afterward is not acceptable),
attempt to move release `api` to image `nginx:this-tag-does-not-exist` (deliberately
unpullable). The command is supposed to exit non-zero, but afterward the release must be back
on healthy, fully available `nginx:1.25-alpine`, with history showing the failed attempt and
the automatic rollback as real revisions.

## Hint

Search helm.sh/docs for **"helm upgrade"** and look for the `--atomic` flag - the docs explain
what it does when combined with `--install` and `--wait`/`--timeout`.
