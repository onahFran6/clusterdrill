# q103-05: Run a fixed-size worker pool that finishes as soon as any one worker succeeds

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-05-job-work-queue-parallelism`

In namespace `q103-05-job-work-queue-parallelism`, create a Job named `queue-workers` that:

- uses image `busybox:1.36`
- runs the command `sh -c "sleep 2 && exit 0"`
- leaves `.spec.completions` **unset**
- sets `.spec.parallelism` to `4`

The Job is done as soon as any one pod succeeds.

## Hint

Search kubernetes.io/docs for **"job work queue"** - the Jobs concept page's "Job Patterns"
section describes the work queue pattern, where completions is left unset and the Job finishes
as soon as one pod succeeds.
