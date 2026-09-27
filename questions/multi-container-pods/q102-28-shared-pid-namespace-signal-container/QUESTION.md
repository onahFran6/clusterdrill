# q102-28: Deliver a signal between sibling containers

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-28-shared-pid-namespace-signal-container`

A Pod named `config-reload-app` already exists with two containers that are
meant to communicate through an OS signal - no shared volume:

- `main` (image `busybox:1.36`) - runs a loop with a `trap` on `SIGHUP` that
  appends a line to `/tmp/main-reload.log` to simulate a config reload.
- `watcher` (image `busybox:1.36`) - every few seconds looks up `main`'s live
  process ID with `ps` (never hardcodes a PID) and sends that process
  `SIGHUP`.

The Pod is Running with both containers Ready, but `watcher`'s signal never
reaches `main` - `/tmp/main-reload.log` inside `main` never gets written.

Fix the Pod so the signal is delivered:

- Enable `spec.shareProcessNamespace: true` at the Pod level.
- `shareProcessNamespace` is immutable on a running Pod - delete and recreate
  `config-reload-app` (same name, same two containers and commands) rather than
  patching the field in place.

Do not change the `main` or `watcher` containers' commands or images.

## Hint

Search kubernetes.io/docs for **"pid namespaces sidecars can see other
containers processes"** - the Pods concept page's Debugging section
explains why one container's `kill -HUP <pid>` normally can't reach a
process in a different container, and what field changes that.
