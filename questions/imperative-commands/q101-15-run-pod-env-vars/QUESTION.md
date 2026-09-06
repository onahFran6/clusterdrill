# q101-15: Create a pod with environment variables set imperatively

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-15-run-pod-env-vars`

In namespace `q101-15-run-pod-env-vars`, create a pod named `env-demo` running image
`busybox:1.36` that sleeps for an hour (so it stays running), with these environment variables set
directly on the container at creation time:

- `APP_ENV=production`
- `RETRY_COUNT=3`

Use a single imperative `kubectl run` command with environment flags - no manifest authored by
hand.

## Hint

Search kubernetes.io/docs for **"kubectl run --env"** - the `kubectl run` command reference
lists the flag for setting one or more container environment variables at creation time.
