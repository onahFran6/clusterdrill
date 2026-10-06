# q111-04: Surge maths and a single-revision release

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-04-rollingupdate-bounds-and-one-revision`

Team Janus runs `relay` (seeded, 10 replicas, `nginx:1.25`, default rolling-update strategy)
and is about to release. Before the release:

- Before changing anything, work out what the *current* default strategy allows: the maximum
  total pods and the minimum available pods during a rollout of 10 replicas.
- Change the strategy so a rollout keeps at least **9** pods available and never runs more than
  **12** pods total.
- Ship image `nginx:1.27` and env var `FEATURE_X=on` as **one** new revision, with change-cause
  `relay 1.27 + feature x`.
- Confirm you ended on exactly one new revision.

## Hint

Search kubernetes.io/docs for **"Rolling Update Deployment"** - the `maxSurge`/`maxUnavailable`
fields section explains how the two bounds combine. "At least 9 available" and "never more than
12" are two different fields; translate each into one number. Two separate `kubectl set` calls
against a live Deployment each start their own rollout unless something stops the controller
between them - look for a `rollout` subcommand that does that.
