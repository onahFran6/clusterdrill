# q110-56: Audit every Helm release, then narrow to just the failed ones without grep

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-56-helm-list-all-namespaces-failed-filter`

`setup.sh` installed three Helm releases into namespace
`q110-56-helm-list-all-namespaces-failed-filter`: `svc-one` and `svc-two` are healthy and
`deployed`; `svc-three` was left `failed` by a botched upgrade. Nobody can currently say, cluster-
wide, which releases exist or which ones are broken.

Produce a full inventory, then narrow it to failed releases only:

1. List every Helm release across every namespace and save the output to
   `~/practice-work/q110-56-helm-list-all-namespaces-failed-filter/all-releases.json`.
2. Using Helm's **own filtering** (not a `grep`/`awk` pipe over step 1's output), list only the
   releases currently in a `failed` state and save that output to
   `~/practice-work/q110-56-helm-list-all-namespaces-failed-filter/failed-releases.json`.

The second file must contain `svc-three` and must not contain `svc-one` or `svc-two`.

## Hint

Search helm.sh/docs for **"helm list"** - the command reference covers the `-A`/`--all-
namespaces` flag for a cluster-wide inventory and the `--failed` flag (alongside
`--deployed`/`--pending`/`--uninstalled`) for filtering by release status without an external
pipe.
