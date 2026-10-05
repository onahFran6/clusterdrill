# q103-29: Suspend a Job that is already running

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-29-suspend-running-job-deletes-pods`

Entropy Research Systems' `report-builder` Job is already `Running` in namespace
`q103-29-suspend-running-job-deletes-pods`, generating a report nobody needs anymore.

Stop `report-builder` right now, in a way that leaves the Job object itself in place and
resumable the same way later - not by deleting the Job, not by deleting its pod directly, and
not by scaling anything.

The Job is suspended only once it reports zero active pods (`.status.active` absent or `0`) and
no pods remain for it in the namespace.

## Hint

Search kubernetes.io/docs for **"job suspend field"** - the Jobs concept page's "Suspending a
Job" section explains what happens to a Job's already running pods when `.spec.suspend` is set
to `true` after the Job has started, versus a Job that was created suspended.
