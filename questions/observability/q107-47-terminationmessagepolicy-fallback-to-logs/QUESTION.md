# q107-47: Surface a failing container's real error via terminationMessagePolicy

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-47-terminationmessagepolicy-fallback-to-logs`

A Pod named `batch-runner` (image `busybox:1.36`) already exists. Its container keeps failing and
prints `custom failure: disk quota exceeded` each time, but the reported termination message is
empty.

Make the termination message fall back to the container's log output on failure, without changing
the command or image. The reported message must contain `custom failure: disk quota exceeded`.

## Hint

Search kubernetes.io/docs for **"customizing the termination message"** - the pod failure
debugging page covers `terminationMessagePolicy: FallbackToLogsOnError`, which uses the last chunk
of a container's own log output as its termination message when nothing was written to
`/dev/termination-log` and the container exited with an error. The default policy is `File`, so
an empty termination file means an empty `Message:` even when the error is in the container log.
