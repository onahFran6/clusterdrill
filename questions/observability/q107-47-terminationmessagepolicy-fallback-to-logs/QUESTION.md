# q107-47: Surface a failing container's real error via terminationMessagePolicy

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-47-terminationmessagepolicy-fallback-to-logs`

`setup.sh` already created a Pod named `batch-runner` (image `busybox:1.36`) whose container keeps
failing, printing `custom failure: disk quota exceeded` to stderr each time - but it never writes
to `/dev/termination-log`, so with the default `terminationMessagePolicy` (`File`), Kubernetes
reports an empty termination message even though the real reason is right there in the container's
own log output. Fix `batch-runner` so its termination message falls back to the container's log
output on failure, without changing the command or image, and confirm the reported message
actually contains `custom failure: disk quota exceeded`.

## Hint

Search kubernetes.io/docs for **"customizing the termination message"** - the pod failure
debugging page covers `terminationMessagePolicy: FallbackToLogsOnError`, which uses the last chunk
of a container's own log output as its termination message when nothing was written to
`/dev/termination-log` and the container exited with an error.
