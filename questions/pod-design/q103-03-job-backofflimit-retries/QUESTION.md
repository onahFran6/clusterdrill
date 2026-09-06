# q103-03: Cap how many times a failing Job retries

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-03-job-backofflimit-retries`

`setup.sh` already created a Job named `flaky-task` in namespace `q103-03-job-backofflimit-retries`.
Its container always exits non-zero, so left alone it retries forever with the default retry
limit.

Edit the Job so that it gives up after **2** failed attempts instead of the default (`.spec.backoffLimit: 2`).
Do not change the container image or command - only the retry behavior.

## Hint

Search kubernetes.io/docs for **"job backoff limit"** - the Jobs concept page's "Pod backoff
failure policy" section shows the `.spec.backoffLimit` field and its default value.
