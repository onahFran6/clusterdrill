# q101-48: Fix a Job that always fails with DeadlineExceeded

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-48-fix-job-activedeadlineseconds-premature-failure`

A Job named `batch-migrate` (image `busybox:1.36`) already exists in namespace
`q101-48-fix-job-activedeadlineseconds-premature-failure`. It needs about 20 seconds to finish,
but it always ends up `Failed` with reason `DeadlineExceeded` before that.

Investigate with `kubectl describe job/batch-migrate`, then fix it. A Job's `spec.template` is
immutable once created, so delete the broken Job and recreate it with the exact same image and
command, but with `activeDeadlineSeconds` raised high enough (at least `30`) that the container is
never killed before it finishes. Let it run to completion.

## Hint

Search kubernetes.io/docs for **"job termination cleanup activedeadlineseconds"** - the Jobs
concept page's "Job Termination and Cleanup" section explains that once
`spec.activeDeadlineSeconds` elapses, the Job is marked `Failed` with reason `DeadlineExceeded` and
all its pods are terminated, regardless of `backoffLimit`.
