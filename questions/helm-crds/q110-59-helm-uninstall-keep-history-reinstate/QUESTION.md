# q110-59-helm-uninstall-keep-history-reinstate: Uninstall without losing history, then bring the release back

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-59-helm-uninstall-keep-history-reinstate`

Release `app` (chart `archiveapp`) is installed in this namespace at revision 1, `deployed`.

1. Uninstall release `app` in a way that removes it from the cluster **without discarding its
   revision history** (a plain uninstall throws history away).
2. Confirm the release is still visible through a history-aware listing even while uninstalled.
3. Bring `app` back to a `deployed` state without hand-writing the manifests again.

## Hint

Search helm.sh/docs for **"helm uninstall"** and **"helm rollback"** - the uninstall reference
covers the flag that preserves release history through an uninstall, and the rollback
reference covers pointing a release back at a specific past revision (which works even after
an uninstall, as long as history wasn't discarded).
