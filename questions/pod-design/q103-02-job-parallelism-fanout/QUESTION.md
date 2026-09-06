# q103-02: Fan a Job out across multiple pods at once

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-02-job-parallelism-fanout`

In namespace `q103-02-job-parallelism-fanout`, create a Job named `render-fanout` that:

- uses image `busybox:1.36`
- runs the command `sleep 3`
- must reach `9` total successful completions (`.spec.completions`)
- runs up to `3` pods **at the same time** (`.spec.parallelism`)

## Hint

Search kubernetes.io/docs for **"job parallel jobs"** - the Jobs concept page's "Parallel Jobs"
section shows how `.spec.parallelism` controls how many pods run concurrently for a
fixed-completion-count Job.
