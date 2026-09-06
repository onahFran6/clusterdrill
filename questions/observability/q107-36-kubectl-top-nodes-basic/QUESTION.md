# q107-36: Check node-level resource usage

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-36-kubectl-top-nodes-basic`

Retrieve current CPU and memory usage for every node in the cluster, and redirect the output into
a file at `$HOME/practice-work/q107-36-kubectl-top-nodes-basic/node-usage.txt` on the terminal
host (not inside any pod).

## Hint

Search kubernetes.io/docs for **"kubectl top"** - the kubectl command reference covers
`kubectl top nodes` (cluster-wide, node-level usage) alongside `kubectl top pods` (per-pod usage
within a namespace).
