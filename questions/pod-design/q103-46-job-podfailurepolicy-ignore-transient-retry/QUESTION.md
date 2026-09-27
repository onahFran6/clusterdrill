# q103-46: Let a transient exit code retry for free without burning backoffLimit

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-46-job-podfailurepolicy-ignore-transient-retry`

A Job named `heartbeat-sync` already exists in namespace
`q103-46-job-podfailurepolicy-ignore-transient-retry`, with `.spec.suspend: true`, so it has
not run. Its container writes an attempt counter to PersistentVolumeClaim `heartbeat-state`,
exits `75` on the first two attempts, and exits `0` on the third. `.spec.backoffLimit` is `1`.

`.spec.podFailurePolicy` is immutable. Delete `heartbeat-sync` and recreate it unsuspended, with
a `podFailurePolicy` rule that matches container exit code `75` and uses `action: Ignore`.
Keep `.spec.backoffLimit: 1`, the same image and command, and the same PersistentVolumeClaim
`heartbeat-state`. The Job is done once it reports `1` successful completion.

## Hint

Search kubernetes.io/docs for **"job pod failure policy Ignore"** - the Jobs concept page's "Pod
failure policy" section lists `Ignore` alongside `FailJob`/`FailIndex`/`Count`. An
`Ignore`-matched failure does not count toward `.spec.backoffLimit`. Without that rule, both
`75` exits count, and `backoffLimit: 1` fails the Job before the third attempt can succeed.
