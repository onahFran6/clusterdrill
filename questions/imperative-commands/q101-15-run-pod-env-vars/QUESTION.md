# q101-15: Create a Pod with environment variables

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-15-run-pod-env-vars`

In namespace `q101-15-run-pod-env-vars`, create a Pod named `env-demo` running image
`busybox:1.36` that sleeps long enough to stay running, with these environment variables set on
the container at creation time:

- `APP_ENV=production`
- `RETRY_COUNT=3`

Use a single imperative `kubectl run` command - no manifest authored by hand.

## Hint

Search kubernetes.io/docs for **"kubectl run --env"** - the `kubectl run` command reference
lists the flag for setting one or more container environment variables at creation time.
