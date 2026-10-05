# q103-43: Speed up a running Job by raising its parallelism in place

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-43-job-parallelism-scale-up-live`

Quantum Research Laboratory's `speedy-batch` Job calibrates six qubit modules one at a time,
in namespace `q103-43-job-parallelism-scale-up-live` (`.spec.completions: 6`,
`.spec.parallelism: 1`). It's already running. Three more test rigs just freed up, and this run
doesn't need to stay throttled to one at a time anymore.

Without deleting or recreating `speedy-batch`, set `.spec.parallelism` to `3` and leave it at
`3`. The Job is done once it reports all `6` successful completions with `.spec.parallelism`
still `3`.

## Hint

Search kubernetes.io/docs for **"controlling parallelism"** - the Jobs concept page's section by
that name covers which of a running Job's spec fields you're allowed to touch after it's already
started, and how the controller reacts when you do.
