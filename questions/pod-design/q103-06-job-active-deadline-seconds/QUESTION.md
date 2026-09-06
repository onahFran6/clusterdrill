# q103-06: Cap the total wall-clock time a Job is allowed to run

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-06-job-active-deadline-seconds`

In namespace `q103-06-job-active-deadline-seconds`, create a Job named `long-runner` that:

- uses image `busybox:1.36`
- runs the command `sleep 120`
- is force-terminated by Kubernetes if it is still running after `5` seconds total, regardless of
  `backoffLimit` (`.spec.activeDeadlineSeconds: 5`)

The Job should end up in a `Failed` state with reason `DeadlineExceeded` well before the container's
own 120-second sleep would finish.

## Hint

Search kubernetes.io/docs for **"job activeDeadlineSeconds"** - the Jobs concept page's "Job
termination and cleanup" section shows how `.spec.activeDeadlineSeconds` bounds the total runtime
of a Job independently of `backoffLimit`.
