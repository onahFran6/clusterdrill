# q103-43: Speed up a running Job by raising its parallelism in place

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-43-job-parallelism-scale-up-live`

A Job named `speedy-batch` already exists in namespace `q103-43-job-parallelism-scale-up-live`
with `.spec.completions: 6` and `.spec.parallelism: 1`. It is already running, one pod at a time.

Without deleting or recreating `speedy-batch`, set `.spec.parallelism` to `3` and leave it at
`3`. The Job is done once it reports all `6` successful completions with `.spec.parallelism`
still `3`.

## Hint

Search kubernetes.io/docs for **"job parallelism mutable"** - the Jobs concept page's "Controlling
parallelism" section notes that `.spec.parallelism` can be changed on a running Job. The
controller uses the new value for completions that are still outstanding. `.spec.completions`
does not work the same way.
