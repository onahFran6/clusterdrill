# q103-25: Fix a Job so each pod writes its own indexed output file

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-25-job-indexed-completion-mode`

In namespace `q103-25-job-indexed-completion-mode` there is a Job named `indexed-writer` and a
PersistentVolumeClaim named `shared-output` (mounted by the Job's pods at `/data`). The Job is
meant to run exactly 3 pods, each writing its **own** distinct file:

- pod with completion index `0` writes `/data/output-0.txt` containing exactly `0`
- pod with completion index `1` writes `/data/output-1.txt` containing exactly `1`
- pod with completion index `2` writes `/data/output-2.txt` containing exactly `2`

The container command already does `echo "${JOB_COMPLETION_INDEX}" > /data/output-${JOB_COMPLETION_INDEX}.txt`
- it relies on Kubernetes injecting a `JOB_COMPLETION_INDEX` environment variable into each pod
that tells that pod which slice of work (which index) it owns. Right now all 3 pods collide and
overwrite the same file instead of producing 3 distinct ones, because the Job is missing the
completion mode that makes Kubernetes inject that variable in the first place.

Fix the Job `indexed-writer` so that:

- it runs with the completion mode that assigns each pod a fixed, unique completion index from
  `0` to `.spec.completions - 1` and injects it as `JOB_COMPLETION_INDEX`
- `.spec.completions` and `.spec.parallelism` both stay `3`
- the container image, command, volume mount, and resource requests/limits are otherwise
  unchanged

Note: the field that controls completion mode is immutable once a Job exists - you cannot
`kubectl edit` or `kubectl patch` it on the running Job. Delete `indexed-writer` and recreate it
with the corrected spec.

Once fixed and the Job completes, all 3 pods must succeed and `/data` must contain exactly the 3
files above with the exact content described.

## Hint

Search kubernetes.io/docs for **"indexed job"** - the Jobs concept page's section on Job
completion mode explains `completionMode: Indexed` and the `JOB_COMPLETION_INDEX` environment
variable it injects into each pod.
