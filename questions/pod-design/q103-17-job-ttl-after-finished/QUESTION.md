# q103-17: Auto-clean a Job a fixed time after it finishes

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-17-job-ttl-after-finished`

In namespace `q103-17-job-ttl-after-finished`, create a Job named `self-cleaning` that:

- uses image `busybox:1.36`
- runs the command `echo done`
- is automatically deleted by the Kubernetes TTL controller `10` seconds after it finishes
  (successfully or not), using `.spec.ttlSecondsAfterFinished`

`check.sh` waits for the Job to complete and then confirms it is removed on its own - you should
not delete it yourself.

## Hint

Search kubernetes.io/docs for **"job ttl seconds after finished"** - the Jobs concept page's
"Clean up finished Jobs automatically" section documents `.spec.ttlSecondsAfterFinished`.
