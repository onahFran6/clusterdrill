# q110-05: Uninstall exactly one of two releases

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-05-helm-list-uninstall`

`setup.sh` installed two Helm releases in namespace `q110-05-helm-list-uninstall`: `worker-a`
and `worker-b`, both from the same `worker` chart.

Uninstall only the `worker-b` release. When you're done, `worker-a` must still be installed and
running, and `worker-b` must no longer appear in `helm list` for this namespace.

## Hint

Search kubernetes.io/docs for **"helm uninstall"** - the Helm uninstall command reference shows
how to remove a single named release, and `helm list` shows what remains afterward.

