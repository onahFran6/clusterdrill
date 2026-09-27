# q103-50: Combine Indexed completion mode with a required nodeAffinity rule

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-50-job-indexed-completion-with-nodeaffinity-required`

An incomplete Job manifest is at
`~/practice-work/q103-50-job-indexed-completion-with-nodeaffinity-required/sharded-worker.yaml`
in your terminal's working directory. It has not been applied yet.

`sharded-worker` needs both of these before you apply it. Both fields are immutable after the
Job exists:

1. `completionMode: Indexed`, so exactly `3` pods each receive a completion index (`0`, `1`,
   `2`) as `JOB_COMPLETION_INDEX`.
2. A required node affinity rule so every pod runs only on this cluster's node, matched by
   `kubernetes.io/hostname`:
   `.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution`.

Keep `.spec.completions: 3`, `.spec.parallelism: 3`, image `busybox:1.36`, and command
`sh -c 'echo "index $JOB_COMPLETION_INDEX"'`. Apply the manifest and confirm all 3 pods succeed.

## Hint

Search kubernetes.io/docs for **"indexed job"** and separately for **"nodeAffinity
requiredDuringSchedulingIgnoredDuringExecution"** - the Jobs concept page covers `completionMode:
Indexed`, and the "Assign Pods to Nodes" concept page covers the node affinity rule shape. A pod
template can use both. `kubectl get nodes` prints the node name. Without `Indexed`,
`JOB_COMPLETION_INDEX` stays empty. The manifest as written has no `completionMode` and no
`affinity` block.
