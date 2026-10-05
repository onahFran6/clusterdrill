# q103-50: Combine Indexed completion mode with a required nodeAffinity rule

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-50-job-indexed-completion-with-nodeaffinity-required`

Fusion Energy Laboratory's `sharded-worker` Job needs to split fixed work across exactly 3
pods, each aware of its own slice, and this single-node cluster means every pod has to land on
the one node that actually exists. An incomplete Job manifest is at
`~/practice-work/q103-50-job-indexed-completion-with-nodeaffinity-required/sharded-worker.yaml`
in your terminal's working directory. It has not been applied yet - both of the things missing
from it are immutable once a Job exists, so getting them right before applying matters.

`sharded-worker` is missing:

1. Whatever makes each of its 3 pods receive a distinct, fixed index (`0`, `1`, `2`) as
   `JOB_COMPLETION_INDEX` - right now nothing would set that variable at all.
2. A required scheduling rule pinning every pod to this cluster's one real node, matched by
   `kubernetes.io/hostname`.

Keep `.spec.completions: 3`, `.spec.parallelism: 3`, image `busybox:1.36`, and command
`sh -c 'echo "index $JOB_COMPLETION_INDEX"'`. Apply the manifest and confirm all 3 pods succeed.

## Hint

Search kubernetes.io/docs for **"job completion mode"** and separately for **"node affinity"** -
the Jobs concept page covers what's needed for `JOB_COMPLETION_INDEX` to actually be populated,
and the "Assign Pods to Nodes" concept page covers the required-node-affinity rule shape. A pod
template can use both. `kubectl get nodes` prints the node name to match against.
