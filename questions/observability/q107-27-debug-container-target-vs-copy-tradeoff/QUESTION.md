# q107-27-debug-container-target-vs-copy-tradeoff: Diagnose a hung process using an ephemeral debug container's process namespace, then confirm via a copied pod

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-27-debug-container-target-vs-copy-tradeoff`

A running pod named `worker-proc` (image `busybox:1.36`) already exists in namespace
`q107-27-debug-container-target-vs-copy-tradeoff`. It does not set `shareProcessNamespace`.

Create a debug copy named exactly `worker-proc-debug`:

- `.spec.shareProcessNamespace` must be `true`
- every container image in the copy must be `busybox:1.36`

Leave the original `worker-proc` pod untouched: it must still exist, still be `Running`, and
must still have `shareProcessNamespace` unset (not `true`).

## Hint

Search kubernetes.io/docs for **"kubectl debug share-processes"** - the debugging running pods
task page's "Copying a Pod while adding a new container" section covers the `--copy-to` and
`--share-processes` flags, and contrasts them with the `--target` flag used against a live pod's
existing process namespace. The original container runs a `sleep` under `sh` as PID 1.
`kubectl debug` with `--target=worker-proc` shares that one container's process namespace even
when the pod-level field is unset, so `ps` inside the ephemeral container can see those
processes. `--share-processes` on a copy is the form that shares one process namespace across
every container, which matters once a pod has more than one app container. The original pod's
command is a loop of `sleep 2 & wait`.
