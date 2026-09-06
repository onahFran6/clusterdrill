# q101-48-fix-job-activedeadlineseconds-premature-failure: Diagnose and fix a Job that always fails with DeadlineExceeded

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-48-fix-job-activedeadlineseconds-premature-failure`

`setup.sh` already created a Job named `batch-migrate` (image `busybox:1.36`) in namespace
`q101-48-fix-job-activedeadlineseconds-premature-failure`. It genuinely needs about 20 seconds to
finish its work, but it always ends up `Failed` with reason `DeadlineExceeded` before that.

Diagnose why using `kubectl describe job/batch-migrate` (look at `spec.activeDeadlineSeconds` versus
how long the container actually runs), then fix it. A Job's `spec.template` is immutable once
created, so the fix is: delete the broken Job and recreate it (for example with
`kubectl create job --dry-run=client -o yaml` piped through an edit, or hand-applying a corrected
manifest) with the exact same image and command, but with `activeDeadlineSeconds` raised high
enough (at least `30`) that the container is never killed before it finishes. Let it run to
completion.

## Hint

Search kubernetes.io/docs for **"job termination cleanup activedeadlineseconds"** - the Jobs
concept page's "Job Termination and Cleanup" section explains that once
`spec.activeDeadlineSeconds` elapses, the Job is marked `Failed` with reason `DeadlineExceeded` and
all its pods are terminated, regardless of `backoffLimit`.
