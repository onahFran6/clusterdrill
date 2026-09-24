# q110-57: Recover both the overrides and the full computed config from a past revision

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-57-helm-get-values-past-revision`

Release `app` (chart `hotfixapp`) in namespace `q110-57-helm-get-values-past-revision` has
been upgraded six times and is now at revision 7. Its chart's `values.yaml` sets
`image: nginx:1.25-alpine`, `buildTag: v1`, and `region: us-east` by default - each upgrade so
far has only ever overridden `buildTag`, nothing else. At **revision 4 specifically**, someone
set `buildTag` to a value nobody wrote down, and it's needed now for a hotfix elsewhere. The
release has since moved on and no longer reflects it.

Retrieve, from **revision 4 specifically** (not the release's current state):

1. Just the user-supplied override(s) that were active at that revision - save the output to
   `~/practice-work/q110-57-helm-get-values-past-revision/revision4-user.json`.
2. The full computed configuration (chart defaults merged with those overrides) as it stood at
   that exact revision - save the output to
   `~/practice-work/q110-57-helm-get-values-past-revision/revision4-all.json`.

The first file should contain only what was explicitly overridden at revision 4; the second
should additionally contain `region: us-east` and `image: nginx:1.25-alpine`, which nobody ever
overrode.

## Hint

Search helm.sh/docs for **"helm get values"** - the command reference covers the `--revision`
flag for pinning to a specific historical revision, and the `--all` flag for the merged
chart-defaults-plus-overrides view versus the user-supplied-only default view.
