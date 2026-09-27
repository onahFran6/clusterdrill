# q103-39: Require a pod to land on a specific node using nodeAffinity

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-39-nodeaffinity-required-hostname-match`

An incomplete pod manifest is at
`~/practice-work/q103-39-nodeaffinity-required-hostname-match/pinned-by-affinity.yaml` in your
terminal's working directory. It has not been applied yet.

The pod must run only on this cluster's node, matched by the `kubernetes.io/hostname` label,
as a hard `.spec.affinity.nodeAffinity` rule. Do not use `.spec.nodeSelector` or `.spec.nodeName`.

Complete `pinned-by-affinity.yaml` with a `requiredDuringSchedulingIgnoredDuringExecution` rule
whose `nodeSelectorTerms` match `kubernetes.io/hostname` `In` this cluster's node name. Apply it
and confirm the pod reaches `Running`. Do not change the container image (`busybox:1.36`) or
command (`sleep 3600`).

## Hint

Search kubernetes.io/docs for **"nodeAffinity requiredDuringSchedulingIgnoredDuringExecution"** -
the "Assign Pods to Nodes" concept page's node affinity section shows the
`nodeSelectorTerms`/`matchExpressions` shape. `kubectl get nodes` prints the node name.
`nodeSelector` is a different field, and `nodeName` bypasses the scheduler.
