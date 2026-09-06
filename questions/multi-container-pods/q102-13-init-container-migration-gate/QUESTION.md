# q102-13: Init container as a migration gate

**Domain:** Application Design and Build · **Points:** 7 · **Namespace:** `q102-13-init-container-migration-gate`

Create a Pod named `migrated-app` with a shared `emptyDir` volume named
`status-vol` and two containers:

- An **init container** named `run-migration` (image `busybox:1.36`) that
  mounts `status-vol` at `/status` and simulates running a one-time
  database migration by writing a marker file when it completes, e.g.
  `sh -c "echo migrated > /status/migration.done"`.
- A main container named `main` (image `busybox:1.36`) that also mounts
  `status-vol` at `/status` and runs a command that reads the marker file
  the init container left behind before continuing, e.g.
  `sh -c "cat /status/migration.done && sleep 3600"`.

Because init containers run to completion before any main container
starts, `main` is guaranteed the migration has finished by the time it
reads `/status/migration.done` - a common CKAD pattern for gating app
startup on a one-time setup step.

The Pod must have exactly one init container.

## Hint

Search kubernetes.io/docs for **"init containers"** - the Workloads / Pods
page's "Init Containers" section describes using them to block application
startup until a precondition (like a completed migration) is met.
