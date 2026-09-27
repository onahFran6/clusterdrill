# q103-25: Fix a Job so each pod writes its own indexed output file

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-25-job-indexed-completion-mode`

In namespace `q103-25-job-indexed-completion-mode` there is a Job named `indexed-writer` and a
PersistentVolumeClaim named `shared-output` (mounted by the Job's pods at `/data`). The Job is
meant to run exactly 3 pods, each writing its own file:

- completion index `0` writes `/data/output-0.txt` containing exactly `0`
- completion index `1` writes `/data/output-1.txt` containing exactly `1`
- completion index `2` writes `/data/output-2.txt` containing exactly `2`

The container command is
`echo "${JOB_COMPLETION_INDEX}" > /data/output-${JOB_COMPLETION_INDEX}.txt`.
Right now the pods overwrite one file instead of writing three distinct files.

Fix `indexed-writer` so that:

- each pod gets a fixed, unique completion index from `0` to `.spec.completions - 1`, exposed as
  `JOB_COMPLETION_INDEX`
- `.spec.completions` and `.spec.parallelism` both stay `3`
- the container image, command, volume mount, and resource requests/limits stay unchanged

Completion mode is immutable on an existing Job. Delete `indexed-writer` and recreate it.
Once the Job completes, all 3 pods must succeed and `/data` must contain exactly those 3 files
with the contents above.

## Hint

Search kubernetes.io/docs for **"indexed job"** - the Jobs concept page's section on Job
completion mode explains `completionMode: Indexed` and the `JOB_COMPLETION_INDEX` environment
variable it injects into each pod. Without that mode, the variable is empty and every pod writes
the same path.
