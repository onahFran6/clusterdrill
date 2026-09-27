# q103-24: Treat one exit code as terminal without burning through backoffLimit

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-24-job-podfailurepolicy-ignore-exit-code`

Two Jobs already exist in namespace `q103-24-job-podfailurepolicy-ignore-exit-code`, both with a
single container named `loader` and `restartPolicy: Never`:

- `code42-loader` always exits `42`. That code means there was nothing new to load and must not
  be retried. The Job currently retries it until `.spec.backoffLimit` is used up.
- `flaky-loader` exits with a different, transient code and **should** keep retrying up to
  `.spec.backoffLimit`. Its current `.spec.podFailurePolicy` matches any nonzero exit and ends
  the Job on the first failed pod.

Fix `.spec.podFailurePolicy` on both Jobs so that:

1. `code42-loader`: exit code `42` fails the Job immediately (`action: FailJob`) via a matching
   `onExitCodes` rule, without extra retry pods.
2. `flaky-loader`: exits other than `42` are not matched by a `FailJob` rule, so the Job retries
   them until `.spec.backoffLimit` is exhausted.

Do not change either Job's `backoffLimit`, container image, or command. Both pod templates must
stay `restartPolicy: Never`.

## Hint

Search kubernetes.io/docs for **"job pod failure policy"** - the Jobs concept page's "Pod failure
policy" section shows the `.spec.podFailurePolicy` field, its `onExitCodes` rules, and why
`restartPolicy: Never` is required for the policy to apply.
