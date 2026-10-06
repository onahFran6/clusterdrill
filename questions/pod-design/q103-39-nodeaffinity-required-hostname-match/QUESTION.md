# q103-39: Require a pod to land on a specific node using nodeAffinity

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-39-nodeaffinity-required-hostname-match`

An incomplete pod manifest is at
`~/practice-work/q103-39-nodeaffinity-required-hostname-match/pinned-by-affinity.yaml` in your
terminal's working directory. It has not been applied yet.

The pod must be scheduled only onto this cluster's node, matched by its `kubernetes.io/hostname`
label - and if no node satisfies that, the pod must stay unscheduled rather than land anywhere
else. Express this as a node affinity rule under `.spec.affinity.nodeAffinity`, not
`.spec.nodeSelector` or `.spec.nodeName`.

Complete `pinned-by-affinity.yaml` with that rule, matching `kubernetes.io/hostname` to this
cluster's actual node name (find it with `kubectl get nodes`). Apply it and confirm the pod
reaches `Running`. Do not change the container image (`busybox:1.36`) or command
(`sleep 3600`).

## Hint

Search kubernetes.io/docs for **"node affinity"** - the "Assign Pods to Nodes" concept page's
node affinity section shows the nested shape (a required vs. a preferred variant) and how to
match a label with an operator.
