# q103-43: Speed up a running Job by raising its parallelism in place

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-43-job-parallelism-scale-up-live`

`setup.sh` already created a Job named `speedy-batch` in namespace `q103-43-job-parallelism-scale-up-live`
with `.spec.completions: 6` and `.spec.parallelism: 1` - it is already running, working through its
6 pods one at a time.

Unlike `.spec.completions`, `.spec.parallelism` is **not** immutable - it can be changed on a Job
that already exists, and the controller picks up the new value immediately for however many
completions remain. Running one pod at a time is unnecessarily slow for this workload.

Without deleting or recreating `speedy-batch`, patch `.spec.parallelism` to `3` so up to three of
its pods run at once for the rest of the run. Leave `.spec.parallelism` at `3` (don't revert it
afterward) and let the Job finish. `speedy-batch` is done once it reports all `6` successful
completions with `.spec.parallelism` still `3`.

## Hint

Search kubernetes.io/docs for **"job parallelism mutable"** - the Jobs concept page's "Controlling
parallelism" section notes that `.spec.parallelism` can be adjusted at any time, unlike most other
Job spec fields.
