# q110-03: Upgrade a release to change an image tag

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-03-helm-upgrade-values`

A Helm release named `site` (chart `webfront`, staged at
`$HOME/practice-work/q110-03-helm-upgrade-values/chart`) is already installed in namespace
`q110-03-helm-upgrade-values` at revision 1 with `image.tag: "1.25-alpine"`.

Upgrade the `site` release in place so `image.tag` becomes `1.27-alpine`, without
uninstalling and reinstalling.

## Hint

Search kubernetes.io/docs for **"helm upgrade"** - the Helm upgrade command reference shows
how to change a release's values in place and how each upgrade advances its revision number.
