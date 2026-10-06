# q111-06: Roll back by change-cause

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-06-rollback-by-change-cause`

Team Terra's `billing` Deployment (seeded, 4 revisions already shipped) has had errors reported
since the last two releases. Finance wants to return to the release labelled `stable release` in
the rollout history.

- Identify the `stable release` revision's number from the rollout history before rolling back.
- Roll `billing` back to the `stable release` revision, and confirm the image the running pods
  end up on.
- Keep at most **3** old revisions for this Deployment from now on.

## Hint

Search kubernetes.io/docs for **"kubectl rollout history"** - its `CHANGE-CAUSE` column gives you
the revision number directly. Before you undo, inspect what that revision actually contains with
`--revision=N`: does it still carry every env var the current broken version has? Keeping old
revisions around is one field on the Deployment spec, documented on the same Deployment concept
page under "Clean up Policy".
