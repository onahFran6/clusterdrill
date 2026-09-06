# q106-02: Run a pod under a specific ServiceAccount

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-02-pod-uses-serviceaccount`

`setup.sh` already created a ServiceAccount named `report-runner` in namespace
`q106-02-pod-uses-serviceaccount`.

Create a pod named `report-job` running image `busybox:1.36` (command `sleep 3600`) that runs
under the `report-runner` ServiceAccount instead of the namespace's `default` ServiceAccount.

## Hint

Search kubernetes.io/docs for **"configure service account"** - the "Add ServiceAccount to a pod"
section shows the exact pod spec field to set.
