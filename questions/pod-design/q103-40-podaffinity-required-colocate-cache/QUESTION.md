# q103-40: Require a pod to colocate with another pod using podAffinity

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-40-podaffinity-required-colocate-cache`

A pod named `primary` already exists in namespace `q103-40-podaffinity-required-colocate-cache`,
labeled `role: primary`, and it is `Running`.

An incomplete manifest for a second pod is at
`~/practice-work/q103-40-podaffinity-required-colocate-cache/replica.yaml` in your terminal's
working directory. It has not been applied. `replica` must be scheduled onto the exact same node
as `primary` - and if no node can satisfy that, it must stay unscheduled rather than land
elsewhere.

Complete `replica.yaml` with a pod affinity rule (not pod anti-affinity) requiring that
colocation with `primary`, matched on a topology domain narrow enough to guarantee the same
physical node - not just the same zone or region. Apply it and confirm `replica` reaches
`Running` on the same node as `primary`. Do not change `replica`'s image (`busybox:1.36`) or
command (`sleep 3600`), and leave `primary` untouched.

## Hint

Search kubernetes.io/docs for **"inter-pod affinity"** - the "Assign Pods to Nodes" concept page
shows `podAffinity` beside `podAntiAffinity`, using the same `labelSelector`/`topologyKey`
shape. Anti-affinity keeps pods apart; this needs the opposite, and the topology key you choose
is what determines how narrowly "together" is defined.
