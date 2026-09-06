# q103-50: Combine Indexed completion mode with a required nodeAffinity rule

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-50-job-indexed-completion-with-nodeaffinity-required`

`setup.sh` wrote an incomplete Job manifest to
`~/practice-work/q103-50-job-indexed-completion-with-nodeaffinity-required/sharded-worker.yaml` in
your terminal's working directory. It has not been applied yet.

`sharded-worker` needs **two** independent fixes at once, both on fields that are immutable once a
Job exists - so whatever you build, it must be right the first time you apply it:

1. **Indexed completion mode.** The Job must run exactly `3` pods, each getting a fixed, unique
   completion index (`0`, `1`, `2`) injected as the `JOB_COMPLETION_INDEX` environment variable -
   that requires `completionMode: Indexed` on `.spec` (the current manifest is missing it, so it
   would run in the default `NonIndexed` mode instead, and every pod's `JOB_COMPLETION_INDEX`
   would be empty).
2. **Required node affinity.** Every pod the Job creates must run only on this cluster's node,
   identified by its `kubernetes.io/hostname` label, expressed as a hard
   `.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution` rule
   (find the node name with `kubectl get nodes`) - the current manifest has no `affinity` block at
   all.

Complete both, keeping `.spec.completions: 3`, `.spec.parallelism: 3`, and the container's image
(`busybox:1.36`) and command (`sh -c 'echo "index $JOB_COMPLETION_INDEX"'`) unchanged. Apply it and
confirm all 3 pods succeed.

## Hint

Search kubernetes.io/docs for **"indexed job"** and separately for **"nodeAffinity
requiredDuringSchedulingIgnoredDuringExecution"** - the Jobs concept page covers `completionMode:
Indexed`, and the "Assign Pods to Nodes" concept page covers the node affinity rule shape, and
nothing stops a pod template from using both at once.
