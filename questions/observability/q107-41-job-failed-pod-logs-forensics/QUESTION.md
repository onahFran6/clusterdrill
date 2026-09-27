# q107-41: Find why a Job's Pods failed, purely by reading logs

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-41-job-failed-pod-logs-forensics`

A Job named `data-migration` already exists in this namespace and has finished failing
(`backoffLimit: 1`), leaving one or more failed Pods behind. Do not change the Job or its Pods.

Read the failed Pod logs and save the exact error line to
`$HOME/practice-work/q107-41-job-failed-pod-logs-forensics/failure-reason.txt` on the terminal
host.

## Hint

Search kubernetes.io/docs for **"kubectl logs"** - the kubectl command reference shows that
`kubectl logs -l <selector>` retrieves logs from every Pod matching a label selector (like a
Job's auto-applied `job-name` label) in one command, without needing the exact Pod name.
