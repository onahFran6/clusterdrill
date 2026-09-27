# q102-29: Rebalance memory limits under a LimitRange ceiling

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-29-limitrange-rebalance-prevent-sidecar-oomkill`

A `LimitRange` named `container-mem-ceiling` already exists in this namespace.
It applies to `Container`-kind objects and caps how much memory any single
container may set as its own `resources.limits.memory`:

- max memory limit per container: `128Mi`

A Pod named `batch-processor` already exists with two containers:

- `main` (image `busybox:1.36`) builds and holds an in-memory buffer of roughly
  86Mi before going idle. Its `resources.requests.memory` and
  `resources.limits.memory` are both only `24Mi`.
- `metrics-sidecar` (image `busybox:1.36`) appends a small heartbeat line every
  15 seconds. Its `resources.limits.memory` is `112Mi`.

`main` is OOMKilled repeatedly (`kubectl get pod batch-processor` shows a
climbing restart count and `lastState.terminated.reason` of `OOMKilled`), while
`metrics-sidecar` sits on headroom it never uses.

Rebalance the two containers' own memory requests/limits without touching the
`LimitRange`:

- Raise `main`'s `resources.requests.memory` and `resources.limits.memory` high
  enough to finish building its ~86Mi buffer without being OOMKilled, while
  staying at or under the `LimitRange`'s 128Mi per-container ceiling.
- Lower `metrics-sidecar`'s `resources.requests.memory` and
  `resources.limits.memory` to match its small footprint.

Do not change either container's name, image, or command, and do not modify
`container-mem-ceiling`. Because a Pod's `resources` are immutable once
running, delete and recreate `batch-processor` with the corrected values.
Confirm `main` stops OOMKilling and stays `Running`/`Ready`, and that
`metrics-sidecar` keeps running normally too.

## Hint

Search kubernetes.io/docs for **"meaning of memory"** - the "Assign Memory
Resources to Containers and Pods" task page explains what happens when a
container tries to use more memory than its own `limits.memory`, and the
LimitRange concept page's "Constraints on Resource Ranges" section explains
how a namespace-level `max` bounds what any one container's own limit may
be set to.
