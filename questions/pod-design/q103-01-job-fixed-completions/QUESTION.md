# q103-01: Create a Job that must run to completion a fixed number of times

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-01-job-fixed-completions`

Helix Genomics Institute batch-verifies checksums for incoming sequencer output. Each file in a
batch must be digested exactly once, and the lab wants files processed strictly in sequence so a
single bad file's retry doesn't fall out of order with the rest.

In namespace `q103-01-job-fixed-completions`, create a Job named `digest-batch` that:

- uses image `busybox:1.36`
- runs the command `sha256sum /etc/hostname`
- completes successfully a total of `6` times (`.spec.completions`)
- runs the pods **one at a time**, not concurrently (the default parallelism)

The Job is done only once 6 pods have each completed successfully.

## Hint

Search kubernetes.io/docs for **"job completions parallel"** - the Jobs concept page explains
the difference between `.spec.completions` and `.spec.parallelism` and shows the manifest fields
for a fixed-completion-count Job.
