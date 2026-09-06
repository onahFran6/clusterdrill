# q103-27: Make the Job's deadline actually cut off its retries

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-27-job-activedeadline-interrupts-backoff`

`setup.sh` already created a Job named `stubborn-retrier` in namespace
`q103-27-job-activedeadline-interrupts-backoff`. Its container always exits non-zero after a short
sleep, and `.spec.backoffLimit` is `6`, so left alone it would retry several times over a couple of
minutes before finally giving up on its own with reason `BackoffLimitExceeded`.

The Job also has `.spec.activeDeadlineSeconds` set, but its current value is too generous to matter -
it never actually interrupts the retries before `backoffLimit` would exhaust them naturally, so the
deadline isn't doing its intended job.

Edit the Job so its deadline actually fires first: set `.spec.activeDeadlineSeconds` to exactly `25`,
so the Job is force-terminated partway through its retry sequence and ends up `Failed` with reason
`DeadlineExceeded` - not `BackoffLimitExceeded`. Do not change the image, command, or `backoffLimit`.

## Hint

Search kubernetes.io/docs for **"job activeDeadlineSeconds"** - the Jobs concept page's "Job
termination and cleanup" section explains that `.spec.activeDeadlineSeconds` bounds a Job's total
active time independently of `.spec.backoffLimit`, and that whichever limit is reached first decides
the Job's failure reason.
