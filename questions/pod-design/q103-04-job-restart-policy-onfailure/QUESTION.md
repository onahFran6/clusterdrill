# q103-04: Retry a failing container in place instead of replacing the pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-04-job-restart-policy-onfailure`

In namespace `q103-04-job-restart-policy-onfailure`, create a Job named `retry-in-place` that:

- uses image `busybox:1.36`
- runs the command `sh -c "exit 1"` (it always fails)
- restarts the **same pod's container** on failure rather than creating a brand-new pod for each
  attempt (`.spec.template.spec.restartPolicy: OnFailure`)
- sets `.spec.backoffLimit` to `3`

You are checking that exactly one pod is created for this Job even though the container restarts
multiple times inside it.

## Hint

Search kubernetes.io/docs for **"pod restart policy job"** - the Jobs concept page explains why
`restartPolicy` for a Job's pod template must be `Never` or `OnFailure`, and how `OnFailure`
restarts the container in the existing pod instead of creating a new one.
