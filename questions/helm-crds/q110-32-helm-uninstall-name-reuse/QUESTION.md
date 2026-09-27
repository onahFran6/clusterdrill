# q110-32-helm-uninstall-name-reuse: Free a release name for reuse with a plain uninstall

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-32-helm-uninstall-name-reuse`

A local Helm chart named `widget` is on disk at
`questions/helm-crds/q110-32-helm-uninstall-name-reuse/chart` (relative to `practice-bank/`).
Release `demo` is already installed in this namespace with image override `busybox:1.36`
(Deployment `demo-widget`).

Uninstall release `demo` without retaining history, then install the same chart again under the
same release name `demo` in this namespace using the chart's default values (no `--set` or
values override). When done, `helm history demo` must show exactly one revision, and
`demo-widget` must run the chart default image `nginx:1.25-alpine`.

## Hint

Search kubernetes.io/docs for **"helm uninstall"** - the Helm uninstall command reference
explains that, without a history-retaining flag, uninstalling a release removes it completely,
freeing its name for a later `helm install` to reuse from scratch.
