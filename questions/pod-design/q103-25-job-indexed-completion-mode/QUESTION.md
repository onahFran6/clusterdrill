# q103-25: Fix a Job so each pod writes its own indexed output file

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-25-job-indexed-completion-mode`

In namespace `q103-25-job-indexed-completion-mode` there is a Job named `indexed-writer` and a
PersistentVolumeClaim named `shared-output` (mounted by the Job's pods at `/data`). The Job is
meant to run exactly 3 pods, each writing its own file:

- completion index `0` writes `/data/output-0.txt` containing exactly `0`
- completion index `1` writes `/data/output-1.txt` containing exactly `1`
- completion index `2` writes `/data/output-2.txt` containing exactly `2`

The container command is
`echo "${JOB_COMPLETION_INDEX}" > /data/output-${JOB_COMPLETION_INDEX}.txt`. Right now all 3
pods collide on the same file instead of writing three distinct ones - `JOB_COMPLETION_INDEX`
comes out empty for every pod.

Fix `indexed-writer` so each pod actually receives a fixed, unique index of its own.
`.spec.completions` and `.spec.parallelism` must both stay `3`, the container image, command,
volume mount, and resource requests/limits must stay unchanged, and the Job must keep its name.
Once it completes, all 3 pods must succeed and `/data` must contain exactly those 3 files with
the contents above.

## Hint

Search kubernetes.io/docs for **"job completion mode"** - the Jobs concept page's section on
this explains why `JOB_COMPLETION_INDEX` comes out empty here and what the Job is currently
missing. Note also which fields on a Job's spec can't just be patched in place.
