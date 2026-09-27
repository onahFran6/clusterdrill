# q102-26: Fix a postStart marker that never reaches the sidecar

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-26-poststart-marker-gates-sidecar-start`

A Pod named `staged-app` already exists in this namespace with two containers
sharing an `emptyDir` volume named `shared`, mounted at `/shared` in both:

- `app` - continuously appends heartbeat lines to `/shared/app.log`. It also
  has a `lifecycle.postStart` `exec` hook that should signal "initial setup is
  done" by writing a marker file to `/shared/ready` a couple of seconds after
  the container starts.
- `log-tailer` - loops, polling for `/shared/ready`. Only once it sees that
  marker does it touch `/shared/log-tailer-active` and start tailing
  `/shared/app.log`.

Right now `log-tailer` never proceeds - it polls forever. The `postStart` hook
on `app` runs and exits successfully, but the marker never appears on the
shared volume where `log-tailer` is watching.

Fix `app`'s `postStart` hook so it writes the `ready` marker to `/shared/ready`.
Do not change either container's name, image, or main `command`, and do not
change `log-tailer`'s wait loop. `postStart` hooks are immutable on a running
Pod - delete and recreate `staged-app` with the corrected hook. Confirm the Pod
comes back `Running` with both containers ready (2/2), and that
`/shared/log-tailer-active` exists.

## Hint

Search kubernetes.io/docs for **"container lifecycle hooks"** - the
Containers concept page's "Container Hooks" section covers `postStart`, how
it runs once right after a container is created, and how it can only be set
at container-creation time (not patched onto a running Pod). Check where the
hook writes its marker relative to the shared mount.
