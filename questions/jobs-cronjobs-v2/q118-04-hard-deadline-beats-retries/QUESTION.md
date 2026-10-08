# q118-04: Stop a report that hangs

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-04-hard-deadline-beats-retries`

Team Jupiter needs *Job* `report` using `busybox:1.36` and `sleep 300` to stop after **20 seconds** for the entire Job, even if retries remain.
Confirm it fails from exceeding that deadline and inspect its failure message.
Observe whether a terminated Pod remains (practice observation, ungraded).

## Hint

Search kubernetes.io/docs for "Job termination and cleanup" and compare Job deadlines with Pod deadlines.
