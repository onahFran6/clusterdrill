# q102-04: Adapter container normalizes log format

**Domain:** Application Design and Build · **Points:** 7 · **Namespace:** `q102-04-adapter-log-format-normalizer`

A Pod named `app` already exists in this namespace with a single container
named `producer` (image `busybox:1.36`) that continuously appends raw lines
like `LEVEL=info MSG=hello` to `/data/raw.log`. The volume backing `/data` is
an `emptyDir` named `shared-data`.

A monitoring system needs these logs as JSON lines instead. Because you
cannot add a container to a running Pod in place, delete and recreate the
`app` Pod, keeping the existing `producer` container's image, volume, and
command unchanged, and add a second container named `adapter` (image
`busybox:1.36`) that:

- Mounts the same `shared-data` volume at `/data`.
- Continuously reads `/data/raw.log` and writes normalized JSON lines (for
  example `{"level":"info","msg":"hello"}`) to `/data/normalized.log`. The
  exact transformation does not need to be perfect - the important part is
  that the adapter container reads from `raw.log` and writes to
  `normalized.log`.

The Pod must end up with exactly two containers: `producer` and `adapter`,
both mounting `shared-data` at `/data` - a classic adapter pattern that
converts one container's output into the format another consumer expects.

## Hint

Search kubernetes.io/docs for **"multi-container pods communicate"** - the
Pods concept page's "Communication between containers in the same Pod"
section describes the adapter container pattern this task is based on.
