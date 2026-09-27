# q103-40: Require a pod to colocate with another pod using podAffinity

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-40-podaffinity-required-colocate-cache`

A pod named `primary` already exists in namespace `q103-40-podaffinity-required-colocate-cache`,
labeled `role: primary`, and it is `Running`.

An incomplete manifest for a second pod is at
`~/practice-work/q103-40-podaffinity-required-colocate-cache/replica.yaml` in your terminal's
working directory. It has not been applied. `replica` must run on the **same node** as `primary`.

Complete `replica.yaml`'s `.spec.affinity.podAffinity` with a
`requiredDuringSchedulingIgnoredDuringExecution` rule whose `labelSelector` matches
`role: primary` and whose `topologyKey` is `kubernetes.io/hostname`. Apply it and confirm
`replica` reaches `Running` on the same node as `primary`. Do not change `replica`'s image
(`busybox:1.36`) or command (`sleep 3600`), and leave `primary` untouched.

## Hint

Search kubernetes.io/docs for **"podAffinity requiredDuringSchedulingIgnoredDuringExecution"** -
the "Assign Pods to Nodes" concept page's inter-pod affinity section shows `podAffinity` beside
`podAntiAffinity`, using the same `labelSelector`/`topologyKey` shape. Anti-affinity keeps pods
apart; this rule keeps them together.
