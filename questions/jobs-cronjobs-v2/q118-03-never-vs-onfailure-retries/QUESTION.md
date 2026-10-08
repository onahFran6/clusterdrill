# q118-03: Compare two import retry strategies

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-03-never-vs-onfailure-retries`

Team Mars is investigating a failing import.
Create *Jobs* `import-never` and `import-onfailure`, both using `busybox:1.36`, `sh -c 'echo importing; exit 1'`, and a retry budget of **2**.
Use `restartPolicy: Never` on the first and `OnFailure` on the second.
Predict their Pod counts and container restart counts before running them, then inspect both failure reasons (practice observations, ungraded).
Both Jobs must finish Failed because their retry budgets were exhausted.

## Hint

Search kubernetes.io/docs for "Pod backoff failure policy" and how container restarts are counted for an OnFailure Job.
