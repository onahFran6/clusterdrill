# q102-29: Rebalance a two-container Pod's memory limits under a LimitRange ceiling

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-29-limitrange-rebalance-prevent-sidecar-oomkill`

`setup.sh` already created a `LimitRange` named `container-mem-ceiling` in this
namespace. It applies to `Container`-kind objects and caps how much memory
**any single container** may set as its own `resources.limits.memory`:

- max memory limit per container: `128Mi`

A Pod named `batch-processor` already exists with two containers:

- `main` (image `busybox:1.36`) does real work: it builds and holds an
  in-memory buffer of roughly 86Mi before going idle, simulating a batch job
  that assembles a report in memory before flushing it. Its own
  `resources.requests.memory` and `resources.limits.memory` are both set to
  only `24Mi`.
- `metrics-sidecar` (image `busybox:1.36`) just appends a small heartbeat
  line to a log file every 15 seconds - its real memory footprint is tiny.
  Its own `resources.limits.memory` is set to `112Mi`, needlessly close to
  the namespace's 128Mi per-container ceiling.

Because `main`'s own memory limit (`24Mi`) is far below what it actually
needs to hold its ~86Mi buffer, the kubelet OOMKills it over and over: check
`kubectl get pod batch-processor` and you'll see its restart count climbing
and `lastState.terminated.reason` reporting `OOMKilled`. Meanwhile
`metrics-sidecar` sits on `112Mi` of headroom it never uses.

Fix this by rebalancing the two containers' **own** memory requests/limits,
not by touching the namespace's `LimitRange`:

- Raise `main`'s `resources.requests.memory` and `resources.limits.memory`
  to a value that reliably lets it finish building its ~86Mi buffer without
  being OOMKilled, while staying at or under the `LimitRange`'s 128Mi
  per-container ceiling.
- Lower `metrics-sidecar`'s `resources.requests.memory` and
  `resources.limits.memory` to a value that actually matches its own small
  footprint, freeing the headroom it was needlessly hoarding.

Do not change either container's name, image, or command, and do not modify
the `container-mem-ceiling` `LimitRange` itself - solve this entirely in the
Pod's own container resources. Because a Pod's `resources` are immutable
once it's running, delete and recreate `batch-processor` with the corrected
values. Confirm `main` stops OOMKilling and stays `Running`/`Ready` under
its real workload, and that `metrics-sidecar` keeps running normally too.

## Hint

Search kubernetes.io/docs for **"meaning of memory"** - the "Assign Memory
Resources to Containers and Pods" task page explains what happens when a
container tries to use more memory than its own `limits.memory`, and the
LimitRange concept page's "Constraints on Resource Ranges" section explains
how a namespace-level `max` bounds what any one container's own limit may
be set to.
