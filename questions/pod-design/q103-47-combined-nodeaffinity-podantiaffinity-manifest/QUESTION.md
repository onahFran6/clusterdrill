# q103-47: Combine a required nodeAffinity rule and a required podAntiAffinity rule on one pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-47-combined-nodeaffinity-podantiaffinity-manifest`

Spectra Observatory's `constrained-worker` pod processes telescope readings and must never share
a node with one of the observatory's legacy pods, which still spikes CPU during its own startup.
An incomplete pod manifest is at
`~/practice-work/q103-47-combined-nodeaffinity-podantiaffinity-manifest/constrained-worker.yaml`
in your terminal's working directory. It has not been applied yet.

The pod needs both rules, both `requiredDuringSchedulingIgnoredDuringExecution`, under one
`.spec.affinity`:

1. **nodeAffinity**: run only on a node where `kubernetes.io/os` is `In` `["linux"]`.
2. **podAntiAffinity**: do not run on a node that already has a pod labeled `app: legacy-worker`
   (`topologyKey: kubernetes.io/hostname`).

Complete `constrained-worker.yaml` with both rules, apply it, and confirm the pod reaches
`Running`. Do not change the container image (`busybox:1.36`) or command (`sleep 3600`).

## Hint

Search kubernetes.io/docs for **"node affinity and pod affinity"** - the "Assign Pods to Nodes"
concept page shows that `.spec.affinity` can hold `nodeAffinity` and `podAntiAffinity` together.
They are sibling fields. This cluster has no pod labeled `app: legacy-worker`, so the
anti-affinity rule can be satisfied; it still has to be present.
