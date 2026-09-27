# q110-57-helm-get-values-past-revision: Recover both the overrides and the full computed config from a past revision

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-57-helm-get-values-past-revision`

Release `app` (chart `hotfixapp`) in this namespace is at revision 7. The chart defaults are
`image: nginx:1.25-alpine`, `buildTag: v1`, and `region: us-east`; upgrades so far have only
overridden `buildTag`. At **revision 4**, `buildTag` was set to a value that is no longer on
the current release and is needed for a hotfix.

From **revision 4** specifically (not the current release state):

1. Save just the user-supplied override(s) active at that revision to
   `~/practice-work/q110-57-helm-get-values-past-revision/revision4-user.json`.
2. Save the full computed configuration (chart defaults merged with those overrides) at that
   revision to `~/practice-work/q110-57-helm-get-values-past-revision/revision4-all.json`.

The first file should contain only what was explicitly overridden at revision 4; the second
should also include `region: us-east` and `image: nginx:1.25-alpine`.

## Hint

Search helm.sh/docs for **"helm get values"** - the command reference covers the `--revision`
flag for pinning to a specific historical revision, and the `--all` flag for the merged
chart-defaults-plus-overrides view versus the user-supplied-only default view.
