# q103-15: Constrain a pod to nodes with a specific built-in label

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-15-pod-nodeselector-os-linux`

In namespace `q103-15-pod-nodeselector-os-linux`, create a pod named `linux-only` that:

- uses image `busybox:1.36`
- runs the command `sleep 3600`
- is only ever scheduled onto nodes with the built-in label `kubernetes.io/os=linux`, using
  `.spec.nodeSelector` (every node in this cluster already carries that label - you are checking
  the pod actually declares the constraint, not working around a scheduling problem)

## Hint

Search kubernetes.io/docs for **"nodeSelector"** - the "Assign Pods to Nodes" page shows the
`.spec.nodeSelector` field and lists the built-in node labels every node carries, including
`kubernetes.io/os`.
