# q107-27-debug-container-target-vs-copy-tradeoff: Diagnose a hung process using an ephemeral debug container's process namespace, then confirm via a copied pod

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-27-debug-container-target-vs-copy-tradeoff`

`setup.sh` already created a running pod named `worker-proc` (image `busybox:1.36`, running a
loop of `sleep 2 & wait`, so its PID 1 is `sh` with a `sleep` child process at any given moment)
in namespace `q107-27-debug-container-target-vs-copy-tradeoff`. The pod does **not** set
`shareProcessNamespace` at the pod level (it defaults to `false`).

First, attach an ephemeral debug container to the *existing* pod and target the `worker-proc`
container so the ephemeral container shares that one container's process namespace:

```sh
kubectl debug -it worker-proc -n q107-27-debug-container-target-vs-copy-tradeoff \
  --image=busybox:1.36 --target=worker-proc -- sh
```

From inside it, run `ps aux` and confirm you can see the `sh`/`sleep` processes from the
`worker-proc` container - `--target` shares process namespaces with that one target container
even though the pod-level `shareProcessNamespace` field is unset.

Now generalize the technique for pods with **multiple** app containers, where you'd want every
container in a debug copy to share a single process namespace rather than targeting just one
container at a time. Create a full debug copy of the pod, named exactly `worker-proc-debug`, with
process namespace sharing turned on for the whole copy, and with every container's image set to
`busybox:1.36`:

- copy name: `worker-proc-debug`
- process namespace sharing enabled for the copy (`.spec.shareProcessNamespace` must be `true`)
- every container image in the copy set to `busybox:1.36`

Leave the original `worker-proc` pod completely untouched - it must still exist, still be
`Running`, and must still have `shareProcessNamespace` unset (not `true`).

## Hint

Search kubernetes.io/docs for **"kubectl debug share-processes"** - the debugging running pods
task page's "Copying a Pod while adding a new container" section covers the `--copy-to` and
`--share-processes` flags, and contrasts them with the `--target` flag used against a live pod's
existing process namespace.
