# q103-39: Require a pod to land on a specific node using nodeAffinity

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-39-nodeaffinity-required-hostname-match`

`setup.sh` wrote an incomplete pod manifest to
`~/practice-work/q103-39-nodeaffinity-required-hostname-match/pinned-by-affinity.yaml` in your
terminal's working directory. It has not been applied yet.

You need this pod to run only on this cluster's node, identified by its `kubernetes.io/hostname`
label - but expressed as a **hard scheduling rule** using `.spec.affinity.nodeAffinity`, not the
simpler `.spec.nodeSelector` field (that's already covered elsewhere) and not `.spec.nodeName`
(that bypasses the scheduler entirely).

Find this cluster's actual node name with `kubectl get nodes`, then complete
`pinned-by-affinity.yaml`'s `.spec.affinity.nodeAffinity` with a
`requiredDuringSchedulingIgnoredDuringExecution` rule whose `nodeSelectorTerms` matches
`kubernetes.io/hostname` `In` that exact node name. Apply it and confirm the pod reaches `Running`.
Do not change the container image (`busybox:1.36`) or command (`sleep 3600`).

## Hint

Search kubernetes.io/docs for **"nodeAffinity requiredDuringSchedulingIgnoredDuringExecution"** -
the "Assign Pods to Nodes" concept page's node affinity section shows the exact
`nodeSelectorTerms`/`matchExpressions` shape this rule needs.
