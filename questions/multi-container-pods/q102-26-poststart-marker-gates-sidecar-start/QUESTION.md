# q102-26-poststart-marker-gates-sidecar-start: postStart hook writes the sidecar's ready marker to the wrong path

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-26-poststart-marker-gates-sidecar-start`

A Pod named `staged-app` already exists in this namespace with two
containers sharing an `emptyDir` volume named `shared`, mounted at
`/shared` in both:

- `app` - continuously appends heartbeat lines to `/shared/app.log`. It
  also has a `lifecycle.postStart` `exec` hook that is supposed to signal
  "initial setup is done" by writing a marker file to `/shared/ready` a
  couple of seconds after the container starts.
- `log-tailer` (the sidecar) - loops, polling for `/shared/ready` to
  appear. Only once it sees that marker does it do its real work: it
  touches `/shared/log-tailer-active` and starts tailing `/shared/app.log`.

Right now `log-tailer` never proceeds - it polls forever. The `postStart`
hook on `app` runs and exits successfully (it does not crash or restart the
container), but it writes its marker to `/tmp/ready` instead of
`/shared/ready`. `/tmp` is `app`'s own private container filesystem, not
the shared volume, so `log-tailer` - watching the actual shared mount - never
sees it.

Fix `app`'s `postStart` hook so it writes the `ready` marker to
`/shared/ready` (the shared volume's mount path), not `/tmp/ready`. Do not
change either container's name, image, or main `command`, and do not change
`log-tailer`'s wait loop. `postStart` hooks are immutable on a running Pod,
so you will need to delete and recreate `staged-app` with the corrected
hook. Confirm the Pod comes back `Running` with both containers ready
(2/2), and that `log-tailer` has genuinely proceeded past its wait loop -
`/shared/log-tailer-active` exists.

## Hint

Search kubernetes.io/docs for **"container lifecycle hooks"** - the
Containers concept page's "Container Hooks" section covers `postStart`, how
it runs once right after a container is created, and how it can only be set
at container-creation time (not patched onto a running Pod).
