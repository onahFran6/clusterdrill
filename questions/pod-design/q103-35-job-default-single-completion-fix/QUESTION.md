# q103-35: Fix a one-shot Job that was wrongly told to run five times

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-35-job-default-single-completion-fix`

`setup.sh` already created a Job named `onetime-cleanup` in namespace
`q103-35-job-default-single-completion-fix` with `.spec.completions: 5`. Whoever wrote it copied
the field from a different, genuinely repeating Job without thinking about what this one actually
does: `onetime-cleanup` runs a cleanup script that is only ever meant to run **exactly once** -
running it 5 times wastes four extra runs for no benefit and, if the script isn't perfectly
idempotent, risks doing the cleanup work more than once.

A Job's `.spec.completions` is immutable once the Job exists, so you cannot `kubectl edit` or
`kubectl patch` your way out of this - delete `onetime-cleanup` and recreate it using the *default*
non-parallel Job pattern (leave both `.spec.completions` and `.spec.parallelism` unset entirely,
which defaults a Job to running exactly one pod to completion). Keep the same name, image
(`busybox:1.36`), and command (`echo cleaning`).

Once recreated, the Job must succeed with exactly `1` completion.

## Hint

Search kubernetes.io/docs for **"job completions parallel"** - the Jobs concept page's
"Non-parallel Jobs" section explains that leaving `.spec.completions` and `.spec.parallelism`
unset is the correct way to express "run this exactly once."
