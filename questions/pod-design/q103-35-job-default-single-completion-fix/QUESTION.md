# q103-35: Fix a one-shot Job that was wrongly told to run five times

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-35-job-default-single-completion-fix`

A Job named `onetime-cleanup` already exists in namespace
`q103-35-job-default-single-completion-fix`. It should run **exactly once**, but
`.spec.completions` is `5`.

`.spec.completions` is immutable. Delete `onetime-cleanup` and recreate it with both
`.spec.completions` and `.spec.parallelism` unset. Keep the same name, image (`busybox:1.36`),
and command (`echo cleaning`).

Once recreated, the Job must succeed with exactly `1` completion.

## Hint

Search kubernetes.io/docs for **"job completions parallel"** - the Jobs concept page's
"Non-parallel Jobs" section explains that leaving `.spec.completions` and `.spec.parallelism`
unset means "run this exactly once." Those fields cannot be patched on an existing Job.
