# q103-23: Bind a pod straight to a node with spec.nodeName

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-23-direct-nodename-assignment`

Quantum Research Laboratory has a workload that must land on this cluster's exact node because
it needs a peripheral wired to that physical machine - the scheduler's normal node-picking is
not welcome here.

An incomplete pod manifest is at
`$HOME/practice-work/q103-23-direct-nodename-assignment/node-pinned.yaml`
(this question's terminal working directory). It has not been applied, so no pod exists in
namespace `q103-23-direct-nodename-assignment` until you create one.

The manifest defines a pod named `node-pinned` running image `busybox:1.36` with command
`sleep 3600`. Its `spec` does not set `nodeName`.

Complete the manifest and create the pod:

- set `.spec.nodeName` to this cluster's node name **before** creating the pod
- apply the manifest so the pod named `node-pinned` exists, keeping the image and command
- the running pod's `.spec.nodeName` must be that node

## Hint

Search kubernetes.io/docs for **"nodeName"** - the "Assign Pods to Nodes" page contrasts
`nodeSelector` with `nodeName`. `kubectl get nodes -o name` prints the node name.
`spec.nodeSelector` only constrains which nodes the scheduler may choose. `spec.nodeName`
assigns the pod to that node at creation time, and the pod never goes through the scheduler.
`nodeName` is immutable after creation, so it cannot be edited or patched onto a running pod.
If the named node does not exist, the pod stays stuck.
