# q103-46: Let a transient exit code retry for free without burning backoffLimit

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-46-job-podfailurepolicy-ignore-transient-retry`

A Job named `heartbeat-sync` already exists in namespace
`q103-46-job-podfailurepolicy-ignore-transient-retry`, with `.spec.suspend: true`, so it has
not run. Its container writes an attempt counter to PersistentVolumeClaim `heartbeat-state`,
exits `75` on the first two attempts (a transient "dependency not ready yet" condition), and
exits `0` on the third. `.spec.backoffLimit` is `1` - too tight to survive two exit-`75`
attempts counted as ordinary failures.

Unsuspend `heartbeat-sync` and fix it so exit code `75` doesn't consume any of that
`backoffLimit` budget - it should be free to retry - while any other kind of failure still
counts normally. Keep `.spec.backoffLimit: 1`, the same image and command, and the same
PersistentVolumeClaim `heartbeat-state`. The Job must keep its name. It's done once it reports
`1` successful completion.

## Hint

Search kubernetes.io/docs for **"job pod failure policy"** - the Jobs concept page's section on
this lists several actions a rule can take on a matched exit code; one of them is for exactly
this "don't count it at all" case. Also note which of a Job's spec fields can't just be patched
once the Job already exists.
