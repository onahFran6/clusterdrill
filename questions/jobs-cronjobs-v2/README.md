# Jobs and CronJobs v2

Twenty original CKAD practice questions on completion, retries, deadlines, scheduled work, and the resources those workloads depend on.
All questions use their folder ID as the namespace, support user namespace suffixes, and grade live cluster state.
The content follows the public [Kubernetes Jobs documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/) and [CronJob documentation](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/).

| Questions | Coverage |
| --- | --- |
| 01-04 | Cleanup delay, completions, concurrency, retry strategies, and Job deadlines |
| 05-06 | Indexed shards, ConfigMaps, and Secret environment variables |
| 07-08 | Persistent results and init containers waiting for Service DNS |
| 09-10 | Pod failure policies, suspended Jobs, and immutable templates |
| 11-15 | Manual runs, real scheduling, overlapping work, history, maintenance, and time zones |
| 16-17 | A ServiceAccount calling the scale API and timestamped PVC backups |
| 18-20 | Invalid manifests, quota admission failures, and NetworkPolicy configuration |

## Cluster requirements

Use a disposable cluster with Kubernetes 1.31 or newer, a default StorageClass, and enough capacity for the normal namespace resource limits.
The storage exercises assume the single-node appliance; their ReadWriteOnce claims need compatible placement if used on a multi-node cluster.
The network exercise checks NetworkPolicy configuration because the appliance does not guarantee a policy-enforcing CNI.
On a CNI that enforces policies, its successful reporter run also demonstrates allowed traffic; the unrelated Pod's blocked request is a practice observation.

## Grading and timing

Each reference solution is one executable shell block in `ANSWER.md`.
Use `lib/verify-question.sh <question-directory>` to check fresh-state zero marks, reference-solution full marks, and cleanup.
The scheduling exercises deliberately wait for real controller activity: question 12 waits three minutes, question 13 waits four minutes, and question 14 observes a two-minute pause.

Question 01 must be graded before its 60-second cleanup delay expires.
After that, the Job and logs are gone; reset and recreate it to grade again.
Question 07 is graded after the Job disappears, using the bound claim and completed reader Pod as durable evidence.
Its final state cannot distinguish automatic cleanup from a manual deletion or recover the deleted Job's exact cleanup delay.

Before/during observations, predicted counts, diagnostic errors, and the pause interval are explicitly ungraded when they cannot be recovered from final cluster state.
The retry exercise does not require the OnFailure Pod to remain after failure, because the Job controller can remove it when the restart budget is exhausted.
The history exercise counts completed successful Jobs owned by its CronJob, with a settling window for cleanup; an active run is outside that history count.

Question 19 deliberately provisions only its custom quota, without a LimitRange that would supply the missing resources and hide the admission failure.
The other questions use the normal namespace limits.
No question creates cluster-scoped resources or changes an existing topic.
