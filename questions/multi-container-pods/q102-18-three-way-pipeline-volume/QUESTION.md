# q102-18: Three-way pipeline volume

**Domain:** Application Design and Build · **Points:** 10 · **Namespace:** `q102-18-three-way-pipeline-volume`

Create a Pod named `pipeline-app` with **three** containers that all mount a
single shared `emptyDir` volume named `pipeline-data` at the path
`/pipeline`, forming a simple three-stage pipeline:

- `generator` (image `busybox:1.36`) - appends an increasing number to
  `/pipeline/stage1.txt` every few seconds, for example:
  `sh -c "i=0; while true; do echo \$i >> /pipeline/stage1.txt; i=\$((i+1)); sleep 5; done"`.
- `processor` (image `busybox:1.36`) - reads `/pipeline/stage1.txt` and
  writes each value doubled to `/pipeline/stage2.txt`, for example a loop
  using `awk` such as
  `sh -c "while true; do awk '{print \$1*2}' /pipeline/stage1.txt >> /pipeline/stage2.txt; sleep 5; done"`.
- `consumer` (image `busybox:1.36`) - tails the final output, for example:
  `sh -c "sleep 5; tail -f /pipeline/stage2.txt"`.

All three containers must mount the same `pipeline-data` volume at
`/pipeline`. This models a multi-stage processing pipeline built from
independent containers that only communicate through a shared filesystem.

The pod must end up with exactly three containers: `generator`, `processor`,
and `consumer`.

## Hint

Search kubernetes.io/docs for **"multi-container pods communicate"** - the
Pods concept page's "Communication between containers in the same Pod"
section shows the shared-volume pattern this task extends to three stages.
