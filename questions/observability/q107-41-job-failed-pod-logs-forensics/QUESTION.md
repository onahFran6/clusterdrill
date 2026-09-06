# q107-41: Find why a Job's Pods failed, purely by reading logs

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-41-job-failed-pod-logs-forensics`

`setup.sh` already created a Job named `data-migration` in this namespace that has finished
failing (`backoffLimit: 1`), leaving one or more failed Pods behind. This is a pure investigation
task - you do not need to fix anything.

Find the failed Pod(s) belonging to this Job and read their logs to determine why they failed.
Redirect the exact error line from the logs into a file at
`$HOME/practice-work/q107-41-job-failed-pod-logs-forensics/failure-reason.txt` on the terminal
host.

## Hint

Search kubernetes.io/docs for **"kubectl logs"** - the kubectl command reference shows that
`kubectl logs -l <selector>` retrieves logs from every Pod matching a label selector (like a
Job's auto-applied `job-name` label) in one command, without needing the exact Pod name.
