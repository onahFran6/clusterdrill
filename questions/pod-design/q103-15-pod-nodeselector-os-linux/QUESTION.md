# q103-15: Constrain a pod to nodes with a specific built-in label

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-15-pod-nodeselector-os-linux`

Atlas Scientific Computing's simulation workloads must never land on anything but a Linux
compute node, even after other operating systems join this cluster's node pool down the line.
In namespace `q103-15-pod-nodeselector-os-linux`, create a pod named `linux-only` that:

- uses image `busybox:1.36`
- runs the command `sleep 3600`
- will only ever be scheduled onto nodes carrying the built-in label `kubernetes.io/os=linux`

## Hint

Search kubernetes.io/docs for **"Assign Pods to Nodes"** - the concept page lists the built-in
labels every node carries (including `kubernetes.io/os`) and the simplest spec field for
constraining scheduling by one of them. Every node in this cluster already satisfies the
constraint; the check is that the pod actually declares it.
