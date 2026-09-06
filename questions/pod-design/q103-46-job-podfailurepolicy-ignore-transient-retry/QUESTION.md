# q103-46: Let a transient exit code retry for free without burning backoffLimit

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-46-job-podfailurepolicy-ignore-transient-retry`

`setup.sh` already created a Job named `heartbeat-sync` in namespace
`q103-46-job-podfailurepolicy-ignore-transient-retry`, currently `.spec.suspend: true` so it has
never actually run. Its container is written to write an attempt counter to a mounted
PersistentVolumeClaim and exit `75` for its first two attempts (simulating a dependency that isn't
ready yet), then exit `0` on the third attempt once the dependency is up. `.spec.backoffLimit` is
`1`.

`.spec.backoffLimit: 1` means the Job normally tolerates only **one** counted pod failure before
giving up entirely (`BackoffLimitExceeded`) - but exit code `75` here isn't a real failure, it's
the container's own signal for "try again shortly, this doesn't count." Right now the Job has no
`.spec.podFailurePolicy`, so if you simply unsuspended it as-is, both `75` exits would count
against `backoffLimit` and the Job would give up permanently after the second one - before the
container ever gets to its third, successful attempt.

`.spec.podFailurePolicy` is immutable once a Job exists, so delete `heartbeat-sync` and recreate it
- unsuspended this time - with a `podFailurePolicy` rule that matches container exits with code
`75` and uses `action: Ignore`, meaning those pod failures are **not** counted toward
`backoffLimit` at all, and the Job just keeps trying. Keep `.spec.backoffLimit: 1`, the same
image/command, and reuse the same PersistentVolumeClaim `heartbeat-state` so the attempt counter
keeps counting up. `heartbeat-sync` is done once it reports `1` successful completion.

## Hint

Search kubernetes.io/docs for **"job pod failure policy Ignore"** - the Jobs concept page's "Pod
failure policy" section lists `Ignore` alongside `FailJob`/`FailIndex`/`Count`, and states that an
`Ignore`-matched failure does not count towards `.spec.backoffLimit`.
