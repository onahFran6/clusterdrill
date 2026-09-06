# q103-40: Require a pod to colocate with another pod using podAffinity

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-40-podaffinity-required-colocate-cache`

`setup.sh` already created a pod named `primary` in namespace
`q103-40-podaffinity-required-colocate-cache`, labeled `role: primary`, and it is `Running`.

It also wrote an incomplete manifest for a second pod to
`~/practice-work/q103-40-podaffinity-required-colocate-cache/replica.yaml` in your terminal's
working directory - not applied yet. `replica` reads from `primary`'s local cache over `localhost`,
so it must always land on the **same node** as `primary` - the opposite goal of pod
anti-affinity, using `.spec.affinity.podAffinity` instead of `.spec.affinity.podAntiAffinity`.

Complete `replica.yaml`'s `.spec.affinity.podAffinity` with a
`requiredDuringSchedulingIgnoredDuringExecution` rule whose `labelSelector` matches `role: primary`
and whose `topologyKey` is `kubernetes.io/hostname`. Apply it and confirm `replica` reaches
`Running` on the same node as `primary`. Do not change `replica`'s container image
(`busybox:1.36`) or command (`sleep 3600`), and leave `primary` untouched.

## Hint

Search kubernetes.io/docs for **"podAffinity requiredDuringSchedulingIgnoredDuringExecution"** -
the "Assign Pods to Nodes" concept page's inter-pod affinity section shows `podAffinity` right
alongside `podAntiAffinity`, using the same `labelSelector`/`topologyKey` shape to express the
opposite goal: keeping pods together instead of apart.
