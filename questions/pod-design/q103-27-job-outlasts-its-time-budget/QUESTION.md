# q103-27: Make the Job's deadline actually cut off its retries

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-27-job-outlasts-its-time-budget`

A Job named `stubborn-retrier` already exists in namespace
`q103-27-job-outlasts-its-time-budget`. Its container always exits non-zero after a
short sleep, and `.spec.backoffLimit` is `6` - left alone, that lets it burn through several
minutes of retries before finally giving up.

Bound the Job's total running time to **25** seconds instead, so it ends `Failed` well before
its retry budget would otherwise run out - and the failure reason must show that the time bound
was what stopped it, not the retry count. Do not change the image, command, or `backoffLimit`.

## Hint

Search kubernetes.io/docs for **"job termination and cleanup"** - the Jobs concept page's
section by that name covers a field that bounds a Job's total active time independently of
`backoffLimit`, and explains which of the two wins when both are in play.
