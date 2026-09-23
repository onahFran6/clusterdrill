# q110-54: Use --atomic so a bad upgrade rolls itself back instead of leaving the release half-broken

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-54-helm-upgrade-install-atomic-rollback`

`setup.sh` installed a Helm release named `api` (chart `atomicapp`) into namespace
`q110-54-helm-upgrade-install-atomic-rollback`, currently revision 1, `deployed`, running
`nginx:1.25-alpine`.

A CI pipeline needs to push a new image tag with **one command** that: works whether the
release already exists or not, blocks until the new pods are actually ready (capped at a
short, bounded timeout instead of the 5-minute default), and - if the new revision can't
become healthy - automatically rolls itself back instead of leaving the release stuck
half-upgraded. Manual `helm rollback` afterward is not acceptable; the self-healing has to be
built into the one upgrade command itself.

Using a single `helm upgrade --install` command with the right flags, attempt to move release
`api` to image `nginx:this-tag-does-not-exist` (deliberately unpullable), with the wait capped
at **60 seconds**. This command is *supposed* to exit non-zero - the image will never become
ready - but because of the flags you used, it must leave the release back on a healthy,
fully-available `nginx:1.25-alpine` afterward, with the release history showing the failed
attempt and the automatic rollback as real revisions (not a silent no-op).

## Hint

Search helm.sh/docs for **"helm upgrade"** and look for the `--atomic` flag - the docs explain
what it does when combined with `--install` and `--wait`/`--timeout`.
