# q103-44: Express a soft node preference with weighted nodeAffinity terms

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-44-nodeaffinity-preferred-weighted-fallback`

`setup.sh` wrote an incomplete pod manifest to
`~/practice-work/q103-44-nodeaffinity-preferred-weighted-fallback/flexible-worker.yaml` in your
terminal's working directory. It has not been applied yet.

This pod should *prefer* Linux nodes strongly, and *prefer* `arm64` nodes more weakly as a
secondary tiebreaker - but it must still be schedulable even if no node satisfies either
preference, unlike `requiredDuringSchedulingIgnoredDuringExecution` (covered elsewhere), which
would leave it permanently `Pending` if nothing matches.

Complete `flexible-worker.yaml`'s `.spec.affinity.nodeAffinity` with a
`preferredDuringSchedulingIgnoredDuringExecution` list containing exactly two weighted terms:

- `weight: 80`, preferring nodes where `kubernetes.io/os` `In` `["linux"]`
- `weight: 20`, preferring nodes where `kubernetes.io/arch` `In` `["arm64"]`

Apply it and confirm the pod reaches `Running`. Do not change the container image
(`busybox:1.36`) or command (`sleep 3600`).

## Hint

Search kubernetes.io/docs for **"nodeAffinity preferredDuringSchedulingIgnoredDuringExecution"** -
the "Assign Pods to Nodes" concept page's node affinity section shows the `weight` field (1-100)
and how multiple preferred terms are each scored and summed, unlike a required rule's all-or-nothing
match.
