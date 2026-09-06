# q103-24: Treat one exit code as terminal without burning through backoffLimit

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-24-job-podfailurepolicy-ignore-exit-code`

`setup.sh` already created two Jobs in namespace `q103-24-job-podfailurepolicy-ignore-exit-code`,
both with a single container named `loader` and `restartPolicy: Never`:

- `code42-loader` - its container always exits with code `42`. In this pipeline, exit code `42`
  means "there was nothing new to load this run" - it is expected, non-retryable business logic,
  not a real failure. Right now the Job has no `.spec.podFailurePolicy`, so it retries this
  "nothing to do" exit like any other failure, wasting every attempt in `.spec.backoffLimit`
  before finally giving up.
- `flaky-loader` - its container always exits with a different, genuinely transient error code.
  This Job **should** keep retrying normally up to its `.spec.backoffLimit`, the same as any
  ordinary failing Job. Right now it already has a `.spec.podFailurePolicy` rule, but that rule is
  far too broad (it matches *any* nonzero exit code) and terminates the Job on the very first
  failed pod, before backoffLimit gets a chance to do its job.

Fix `.spec.podFailurePolicy` on both Jobs so that:

1. `code42-loader`: a pod that exits with code `42` makes the Job fail immediately
   (`action: FailJob`) via a matching `onExitCodes` rule, without spawning any additional retry
   pods.
2. `flaky-loader`: pods that exit with any code other than `42` are **not** matched by any
   `FailJob` rule, so the Job keeps retrying them normally until `.spec.backoffLimit` is
   exhausted, exactly like default Job failure handling.

Do not change either Job's `backoffLimit`, container image, or command - only
`.spec.podFailurePolicy`. Both Jobs' pod templates must remain `restartPolicy: Never` (required
for `podFailurePolicy` to apply).

## Hint

Search kubernetes.io/docs for **"job pod failure policy"** - the Jobs concept page's "Pod failure
policy" section shows the `.spec.podFailurePolicy` field, its `onExitCodes` rules, and why
`restartPolicy: Never` is required.
