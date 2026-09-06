# q102-43-resourcefieldref-memory-divisor: Wrong divisor turns a mebibyte count into a raw byte count

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-43-resourcefieldref-memory-divisor`

A Pod named `sized-worker` already exists in this namespace with two
containers:

- `worker` (busybox:1.36, `limits.memory: 64Mi`) exposes its own memory
  limit to itself as an environment variable `MEM_LIMIT_MB`, via the
  Downward API's `resourceFieldRef` (`resource: limits.memory`), and writes
  that value to `/data/mem_limit_mb.txt`. The intent is for `MEM_LIMIT_MB`
  to hold the limit in mebibytes (`64`), so `worker` can size an in-memory
  cache proportionally.
- `validator` (busybox:1.36) - an unrelated second container, not part of
  this bug, just idles.

`worker`'s `resourceFieldRef.divisor` is set to `"1"` instead of `"1Mi"`,
so `MEM_LIMIT_MB` ends up holding the limit in raw **bytes**
(`67108864`) instead of mebibytes (`64`). Nothing crashes -
`kubectl get pod sized-worker` shows `2/2 Running` the whole time, but
`/data/mem_limit_mb.txt` contains the wrong number.

Fix `worker`'s `resourceFieldRef.divisor` so it is `1Mi` instead of `1`. Do
not change `resource: limits.memory`, the Pod's actual memory limit, either
container's image, or `validator` at all. This field is immutable on a
running Pod - delete and recreate `sized-worker` with the fix applied,
keeping every other field unchanged. Once fixed, `/data/mem_limit_mb.txt`
inside `worker` must contain exactly `64`.

## Hint

Search kubernetes.io/docs for **"expose container resources API"** - the
"Expose Pod Information to Containers Through Environment Variables" task
page's `resourceFieldRef` example shows how `divisor` converts a
container's raw resource value (bytes, for memory) into the unit an
application actually expects.
