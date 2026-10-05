# q103-21: Un-suspend a Job so it actually runs

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-21-job-suspend-unsuspend`

Fusion Energy Laboratory's `archive-purge` Job clears out old simulation output. It already
exists in namespace `q103-21-job-suspend-unsuspend`, created with `.spec.suspend` set to `true`
during a storage migration and never flipped back - right now it has `0` active pods and `0`
succeeded.

Un-suspend `archive-purge` so it starts running and finishes. It is done only once it reports
`1` successful completion (`.status.succeeded`).

## Hint

Search kubernetes.io/docs for **"job suspend field"** - the Jobs concept page's "Suspending a
Job" section shows the `.spec.suspend` field and how it affects an already-created Job. That
field is on the Job itself. Suspending a CronJob only stops future Job creation.
