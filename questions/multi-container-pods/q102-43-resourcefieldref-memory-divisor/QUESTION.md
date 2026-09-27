# q102-43: Expose a memory limit in mebibytes via resourceFieldRef

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-43-resourcefieldref-memory-divisor`

A Pod named `sized-worker` already exists in this namespace with two
containers:

- `worker` (busybox:1.36, `limits.memory: 64Mi`) exposes its own memory
  limit to itself as an environment variable `MEM_LIMIT_MB`, via the
  Downward API's `resourceFieldRef` (`resource: limits.memory`), and writes
  that value to `/data/mem_limit_mb.txt`. The intent is for `MEM_LIMIT_MB`
  to hold the limit in mebibytes (`64`).
- `validator` (busybox:1.36) - an unrelated second container that idles.

Nothing crashes - `kubectl get pod sized-worker` shows `2/2 Running` - but
`/data/mem_limit_mb.txt` does not contain `64`.

Fix `worker`'s `resourceFieldRef.divisor` so it is `1Mi`. Do not change
`resource: limits.memory`, the Pod's actual memory limit, either container's
image, or `validator`. This field is immutable on a running Pod - delete and
recreate `sized-worker` with the fix applied, keeping every other field
unchanged. Once fixed, `/data/mem_limit_mb.txt` inside `worker` must contain
exactly `64`.

## Hint

Search kubernetes.io/docs for **"expose container resources API"** - the
"Expose Pod Information to Containers Through Environment Variables" task
page's `resourceFieldRef` example shows how `divisor` converts a
container's raw resource value (bytes, for memory) into the unit an
application actually expects.
