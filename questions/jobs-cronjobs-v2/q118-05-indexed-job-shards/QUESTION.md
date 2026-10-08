# q118-05: Process one customer shard per Pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-05-indexed-job-shards`

Team Saturn has *ConfigMap* `shards` with keys `0`, `1`, and `2`.
Create *Job* `shard-worker` using `busybox:1.36`, with three completions running in parallel.
Each Pod must process its own stable index and print `shard <index>: <contents>` from the corresponding mounted ConfigMap file.
Keep every Pod command identical and confirm the three sorted logs match the three shards.

## Hint

Search kubernetes.io/docs for "Indexed Jobs" and how a completion index is exposed inside the container.
