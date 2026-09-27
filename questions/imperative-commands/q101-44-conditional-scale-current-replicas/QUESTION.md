# q101-44: Scale with a current-replicas precondition

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-44-conditional-scale-current-replicas`

A Deployment named `queue-consumer` (image `busybox:1.36`, 3 replicas) already exists in
namespace `q101-44-conditional-scale-current-replicas`.

Scale `queue-consumer` to `5` replicas, but only if its replica count is still exactly `3` at the
moment the scale is applied - use `kubectl scale`'s built-in precondition flag in a single
imperative command, rather than reading the replica count yourself first.

## Hint

Search kubernetes.io/docs for **"kubectl scale"** - the kubectl reference documents the
`--current-replicas` flag on `kubectl scale`, which only applies the scale if the object's replica
count still matches the value given, failing safely otherwise.
