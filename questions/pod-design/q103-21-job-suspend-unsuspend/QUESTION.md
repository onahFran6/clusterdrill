# q103-21: Un-suspend a Job so it actually runs

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-21-job-suspend-unsuspend`

`setup.sh` already created a Job named `archive-purge` in namespace
`q103-21-job-suspend-unsuspend`. The Job object exists, but it was created with
`.spec.suspend` set to `true` directly on the Job itself - so the Job controller has never
started a single pod for it: `0` active, `0` succeeded.

This is **not** the same thing as pausing a CronJob's schedule (that's `.spec.suspend` on the
CronJob, which only stops *future* Job creation). Here the Job itself already exists and is
sitting suspended - a plain Job resource also has its own `.spec.suspend` field, and toggling it
is what lets an already-created Job start (or stop) running its pods.

Un-suspend `archive-purge` so it starts running, and let it finish. The Job is done only once
it reports `1` successful completion (`.status.succeeded`).

## Hint

Search kubernetes.io/docs for **"job suspend field"** - the Jobs concept page's "Suspending a
Job" section shows the `.spec.suspend` field and how it affects an already-created Job.
