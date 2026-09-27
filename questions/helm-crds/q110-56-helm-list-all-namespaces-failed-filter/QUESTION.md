# q110-56-helm-list-all-namespaces-failed-filter: Audit every Helm release, then narrow to just the failed ones without grep

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-56-helm-list-all-namespaces-failed-filter`

Three Helm releases exist in this namespace: `svc-one` and `svc-two` are `deployed`;
`svc-three` is `failed`.

Produce a full inventory, then narrow it to failed releases only:

1. List every Helm release across every namespace and save the output to
   `~/practice-work/q110-56-helm-list-all-namespaces-failed-filter/all-releases.json`.
2. Using Helm's own filtering (not a `grep`/`awk` pipe over step 1's output), list only
   releases currently in a `failed` state and save that output to
   `~/practice-work/q110-56-helm-list-all-namespaces-failed-filter/failed-releases.json`.

The second file must contain `svc-three` and must not contain `svc-one` or `svc-two`.

## Hint

Search helm.sh/docs for **"helm list"** - the command reference covers the `-A`/`--all-
namespaces` flag for a cluster-wide inventory and the `--failed` flag (alongside
`--deployed`/`--pending`/`--uninstalled`) for filtering by release status without an external
pipe.
