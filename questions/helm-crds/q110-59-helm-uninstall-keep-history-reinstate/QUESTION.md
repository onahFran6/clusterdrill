# q110-59: Uninstall without losing history, then bring the release back

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-59-helm-uninstall-keep-history-reinstate`

`setup.sh` installed a Helm release named `app` (chart `archiveapp`) into namespace
`q110-59-helm-uninstall-keep-history-reinstate`, currently revision 1, `deployed`. Compliance
wants it removed from the cluster today, but auditors need the option to reinstate it exactly
as it was without anyone re-authoring the manifests from scratch.

1. Uninstall release `app` in a way that removes it from the cluster **without discarding its
   revision history** - a plain `helm uninstall` throws the history away; you need the flag
   that doesn't.
2. Confirm the release is still visible through a history-aware listing (`helm history app` or
   `helm list`) even while uninstalled.
3. Bring `app` back into a `deployed` state, proving the "reinstate" option actually works -
   without hand-writing the manifests again.

## Hint

Search helm.sh/docs for **"helm uninstall"** and **"helm rollback"** - the uninstall reference
covers the flag that preserves release history through an uninstall, and the rollback
reference covers pointing a release back at a specific past revision (which works even after
an uninstall, as long as history wasn't discarded).
