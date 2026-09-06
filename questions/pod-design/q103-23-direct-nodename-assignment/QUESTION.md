# q103-23: Bind a pod straight to a node with spec.nodeName

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-23-direct-nodename-assignment`

`setup.sh` wrote an incomplete pod manifest to
`$HOME/practice-work/q103-23-direct-nodename-assignment/node-pinned.yaml`
(this question's terminal working directory - shown above the terminal panel, and where a new
terminal tab starts). It has not been applied yet, so no pod exists in namespace
`q103-23-direct-nodename-assignment` until you create one.

The manifest defines a pod named `node-pinned` running image `busybox:1.36` with command
`sleep 3600`, but its `spec` is missing the one field this task is about: `nodeName`.

Complete the manifest and create the pod:

- find this cluster's actual node name (for example with `kubectl get nodes -o name`)
- add `.spec.nodeName`, set to that exact node name, **before** creating the pod
- apply the manifest so the pod named `node-pinned` actually exists, keeping the image and
  command exactly as given above
- confirm the running pod's `.spec.nodeName` really is that node

**`nodeName` vs `nodeSelector` - do not confuse the two:** `spec.nodeSelector` (seen elsewhere in
this bank) only *constrains which nodes the scheduler is allowed to pick from* - the pod still
goes through the normal scheduling process. `spec.nodeName`, which this task uses, is a
completely different mechanism: setting it directly assigns the pod to that node **at creation
time**, and the pod never goes through the scheduler at all. Because of that, `nodeName` must be
set before the pod is created - it is immutable once the pod exists, so you cannot `kubectl edit`
or `kubectl patch` it onto a running pod. If the named node doesn't exist (or is unschedulable),
the pod is simply stuck, since nothing ever tries to find it a different one.

## Hint

Search kubernetes.io/docs for **"nodeName"** - the "Assign Pods to Nodes" page contrasts
`nodeSelector` with the simpler, scheduler-bypassing `nodeName` field.
