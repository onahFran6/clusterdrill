# q103-05: Run a fixed-size worker pool that finishes as soon as any one worker succeeds

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-05-job-work-queue-parallelism`

Fusion Energy Laboratory's plasma-stability sweep hands independent parameter sets to whichever
worker picks them up next from a shared queue. Nobody knows in advance how many parameter sets
there are - only that the sweep is done the moment any one worker reports success.

In namespace `q103-05-job-work-queue-parallelism`, create a Job named `queue-workers` that runs
**4** workers in parallel, each using image `busybox:1.36` running command
`sh -c "sleep 2 && exit 0"`. The Job must be considered done as soon as any one worker exits
successfully - don't tell it how many successes to expect.

## Hint

Search kubernetes.io/docs for **"job patterns"** - the Jobs concept page lists a handful of
common patterns for running several parallel Pods. One of them is for exactly this kind of
external-queue work, and the field you'd normally set to a completion count needs different
treatment there.
