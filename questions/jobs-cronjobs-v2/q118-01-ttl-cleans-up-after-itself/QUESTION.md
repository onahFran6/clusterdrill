# q118-01: Clean up a finished date stamp

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-01-ttl-cleans-up-after-itself`

Team Mercury needs a one-off *Job* `stamp` using `busybox:1.36` and `sh -c 'date; hostname'`.
Have Kubernetes delete the Job and its Pods **60 seconds** after it finishes.
Confirm completion and read its log, which must contain the date and Pod hostname.
Run Check before the cleanup delay expires.
After grading, watch the Job disappear on its own (practice observation, ungraded).

## Hint

Search kubernetes.io/docs for "automatic cleanup for finished Jobs" and compare where Job fields and Pod template fields live.
