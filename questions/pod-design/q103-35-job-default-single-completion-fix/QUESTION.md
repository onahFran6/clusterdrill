# q103-35: Fix a one-shot Job that was wrongly told to run five times

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-35-job-default-single-completion-fix`

A Job named `onetime-cleanup` already exists in namespace
`q103-35-job-default-single-completion-fix`. It should run **exactly once**, but it's currently
configured to run five times instead.

Fix `onetime-cleanup` so it runs exactly once, keeping the same name, image (`busybox:1.36`),
and command (`echo cleaning`). Once fixed, the Job must succeed with exactly `1` completion.

## Hint

Search kubernetes.io/docs for **"job non-parallel jobs"** - the Jobs concept page explains what
controls how many times a Job runs, and one important caveat about changing that on a Job that
already exists.
