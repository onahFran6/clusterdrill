# q103-27: Make the Job's deadline actually cut off its retries

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-27-job-activedeadline-interrupts-backoff`

A Job named `stubborn-retrier` already exists in namespace
`q103-27-job-activedeadline-interrupts-backoff`. Its container always exits non-zero after a
short sleep, and `.spec.backoffLimit` is `6`. `.spec.activeDeadlineSeconds` is set, but the
deadline does not end the Job before the retries run out.

Set `.spec.activeDeadlineSeconds` to exactly `25` so the Job ends `Failed` with reason
`DeadlineExceeded`, not `BackoffLimitExceeded`. Do not change the image, command, or
`backoffLimit`.

## Hint

Search kubernetes.io/docs for **"job activeDeadlineSeconds"** - the Jobs concept page's "Job
termination and cleanup" section explains that `.spec.activeDeadlineSeconds` bounds a Job's total
active time independently of `.spec.backoffLimit`, and that whichever limit is reached first
decides the failure reason. The deadline currently on this Job is too long to fire first.
