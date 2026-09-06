# q103-47: Combine a required nodeAffinity rule and a required podAntiAffinity rule on one pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-47-combined-nodeaffinity-podantiaffinity-manifest`

`setup.sh` wrote an incomplete pod manifest to
`~/practice-work/q103-47-combined-nodeaffinity-podantiaffinity-manifest/constrained-worker.yaml`
in your terminal's working directory. It has not been applied yet.

This pod has two independent scheduling requirements at once, both hard requirements, both using
`requiredDuringSchedulingIgnoredDuringExecution` under the same `.spec.affinity` block:

1. **nodeAffinity**: the pod must only run on a node labeled `kubernetes.io/os` `In` `["linux"]`.
2. **podAntiAffinity**: the pod must not run on any node that already has a pod matching label
   `app: legacy-worker` (`topologyKey: kubernetes.io/hostname`) - this cluster has no such pod, so
   this rule is satisfiable, it just also needs to be present and written correctly.

Both rules must exist together under `.spec.affinity` - `.spec.affinity.nodeAffinity` and
`.spec.affinity.podAntiAffinity` are siblings, not alternatives. Complete
`constrained-worker.yaml` with both, apply it, and confirm the pod reaches `Running`. Do not
change the container image (`busybox:1.36`) or command (`sleep 3600`).

## Hint

Search kubernetes.io/docs for **"node affinity and pod affinity"** - the "Assign Pods to Nodes"
concept page shows that `.spec.affinity` can hold `nodeAffinity`, `podAffinity`, and
`podAntiAffinity` together, each independently required for the pod to schedule.
