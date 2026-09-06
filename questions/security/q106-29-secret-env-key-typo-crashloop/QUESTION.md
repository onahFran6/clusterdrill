# q106-29-secret-env-key-typo-crashloop: Diagnose a CrashLoopBackOff caused by referencing a nonexistent Secret key

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-29-secret-env-key-typo-crashloop`

`setup.sh` already created, in namespace `q106-29-secret-env-key-typo-crashloop`, a Secret named
`db-creds` with keys `username` and `password`, and a Pod named `billing-worker` (image
`busybox:1.36`) whose container sources an environment variable `DB_PASS` from that Secret via
`secretKeyRef`. The Pod is not reaching `Running`.

Investigate why `billing-worker` is failing (`kubectl describe pod` and its Events are a good
place to start), identify the root cause, and fix it so that:

- Secret `db-creds` still exists with its keys `username` and `password` unchanged.
- Pod `billing-worker` reaches the `Running` phase.
- Inside the running container, environment variable `DB_PASS` has the exact same value as
  the `password` key stored in `db-creds`.

You may patch the existing Pod object or delete and recreate it, as long as the final Pod is
still named `billing-worker` in this namespace.

## Hint

Search kubernetes.io/docs for **"CreateContainerConfigError"** and separately for **"define
container environment variables using secret data"** - the Debug Pods page explains how to read
Pod Events for a config error, and the Secrets task page shows the exact `secretKeyRef` shape a
container's `env` entry needs.
