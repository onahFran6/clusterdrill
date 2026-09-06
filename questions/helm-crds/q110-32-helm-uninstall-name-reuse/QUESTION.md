# q110-32-helm-uninstall-name-reuse: Free a release name for reuse with a plain uninstall

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-32-helm-uninstall-name-reuse`

`setup.sh` staged a local Helm chart named `widget` on disk at
`questions/helm-crds/q110-32-helm-uninstall-name-reuse/chart` (relative to the
`practice-bank/` directory) and installed it as release `demo` into namespace
`q110-32-helm-uninstall-name-reuse`, overriding the chart's default image with
`--set image=busybox:1.36`.

First, uninstall the `demo` release - a **plain** `helm uninstall`, with no history-retaining
flag. Then install the same chart again under the **same release name**, `demo`, into the same
namespace, this time using the chart's **default** values - do not pass `--set` or any values
override. Because a plain uninstall (unlike one that keeps history) fully frees the release
name, this second install must succeed as a brand-new release at revision 1, with the
Deployment now running the chart's default image (`nginx:1.25-alpine`), not the old override.

## Hint

Search kubernetes.io/docs for **"helm uninstall"** - the Helm uninstall command reference
explains that, without a history-retaining flag, uninstalling a release removes it completely,
freeing its name for a later `helm install` to reuse from scratch.
