# q103-04: Retry a failing container in place instead of replacing the pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-04-job-restart-policy-onfailure`

Vector Bioinformatics Lab's `retry-in-place` Job re-attempts a flaky alignment step. The
platform team wants failed attempts retried inside the same Pod object rather than spinning up a
brand-new Pod for every attempt - fewer Pod objects churning through the API server, and an
easier trail to follow in `kubectl get events`.

In namespace `q103-04-job-restart-policy-onfailure`, create a Job named `retry-in-place` that:

- uses image `busybox:1.36`
- runs the command `sh -c "exit 1"` (it always fails)
- restarts the **same pod's container** on failure rather than creating a brand-new pod for each
  attempt
- sets `.spec.backoffLimit` to `3`

You are checking that exactly one pod is created for this Job even though the container restarts
multiple times inside it.

## Hint

Search kubernetes.io/docs for **"pod restart policy job"** - the Jobs concept page explains that
a Job's pod template `restartPolicy` must be `Never` or `OnFailure`, and that the two behave
differently for what happens to the Pod object itself when the container fails.
