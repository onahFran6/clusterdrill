# q103-44: Express a soft node preference with weighted nodeAffinity terms

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-44-nodeaffinity-preferred-weighted-fallback`

An incomplete pod manifest is at
`~/practice-work/q103-44-nodeaffinity-preferred-weighted-fallback/flexible-worker.yaml` in your
terminal's working directory. It has not been applied yet.

The pod should prefer Linux nodes strongly, and `arm64` nodes more weakly, and it must still
schedule when neither preference matches.

Complete `flexible-worker.yaml`'s `.spec.affinity.nodeAffinity` with a
`preferredDuringSchedulingIgnoredDuringExecution` list of exactly two weighted terms:

- `weight: 80`, preferring nodes where `kubernetes.io/os` `In` `["linux"]`
- `weight: 20`, preferring nodes where `kubernetes.io/arch` `In` `["arm64"]`

Apply it and confirm the pod reaches `Running`. Do not change the container image
(`busybox:1.36`) or command (`sleep 3600`).

## Hint

Search kubernetes.io/docs for **"nodeAffinity preferredDuringSchedulingIgnoredDuringExecution"** -
the "Assign Pods to Nodes" concept page's node affinity section shows the `weight` field (1-100)
and how multiple preferred terms are scored and summed.
`requiredDuringSchedulingIgnoredDuringExecution` would leave the pod Pending when nothing
matches. Preferred rules do not.
