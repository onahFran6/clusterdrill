# q104-23: Record why a stalled rollout failed

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-23-detect-progress-deadline-exceeded`

A Deployment named `report-generator` already exists in namespace
`q104-23-detect-progress-deadline-exceeded` with 2 replicas and
`spec.progressDeadlineSeconds: 20`. A rolling update to a bad image tag has stalled: the new
pods never become Ready, and the Deployment's `Progressing` condition now reports
`status: False`.

Without changing the Deployment's image or any other field, inspect the Deployment and find
the `reason` on that `Progressing` condition. Create a throwaway Pod named `checker` in the
same namespace (image `busybox:1.36`, `restartPolicy: Never`) whose container command writes
that exact reason string to `/tmp/deadline-reason.txt` inside the pod, then sleeps so the pod
stays inspectable (for example `sh -c "echo <reason> > /tmp/deadline-reason.txt; sleep 3600"`).

## Hint

Search kubernetes.io/docs for **"ProgressDeadlineExceeded"** - the Deployments concept page's
"Failed Deployment" section shows how `kubectl describe deployment` /
`kubectl get deployment -o jsonpath` surface a stalled rollout's `Progressing` condition
reason once the progress deadline has elapsed.
