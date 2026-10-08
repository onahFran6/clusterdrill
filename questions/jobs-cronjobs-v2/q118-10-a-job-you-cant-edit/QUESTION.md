# q118-10: Repair an export waiting for its data window

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-10-a-job-you-cant-edit`

Team Vesta has suspended *Job* `export` with an image that cannot run.
Inspect its Pod count while suspended and try correcting the image in place; read the rejection (practice observations, ungraded).
Get `export` to finish successfully using `busybox:1.36`, preserving its name and `echo exporting` command.
Create the corrected Job suspended, then release it when ready.

## Hint

Search kubernetes.io/docs for "suspending a Job" and which Pod template fields can be changed after creation.
