# q102-28: Signal a sibling container's process via a shared PID namespace

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-28-shared-pid-namespace-signal-container`

This namespace already has a Pod named `config-reload-app` with two
containers that are meant to communicate purely through an OS signal - no
shared volume, no shared network trick, just one container sending another
a signal:

- `main` (image `busybox:1.36`) - the "application": runs a loop, and has
  a `trap` on `SIGHUP` that appends a line to `/tmp/main-reload.log` inside
  its own filesystem to simulate reloading its config.
- `watcher` (image `busybox:1.36`) - a "config-watcher" sidecar: every few
  seconds it looks up `main`'s live process ID with `ps` (it never
  hardcodes a PID) and sends that process `SIGHUP`, so `main` picks up the
  simulated config change.

The Pod is Running with both containers Ready, but `watcher`'s signal never
actually reaches `main` - `/tmp/main-reload.log` inside the `main`
container never gets written to. Fix the Pod so the signal really gets
delivered:

- Enable `spec.shareProcessNamespace: true` at the Pod level, so all
  containers in the Pod share one PID namespace and can see (and signal)
  each other's processes instead of each container only seeing its own.
- `shareProcessNamespace` is immutable on a running Pod - delete and
  recreate the Pod `config-reload-app` (same name, same two containers and
  commands) rather than trying to patch the field in place.

Do not change the `main` or `watcher` containers' commands or images -
they are already correct; the only thing missing is process namespace
sharing between them.

## Hint

Search kubernetes.io/docs for **"pid namespaces sidecars can see other
containers processes"** - the Pods concept page's Debugging section
explains why one container's `kill -HUP <pid>` normally can't reach a
process in a different container, and what field changes that.
