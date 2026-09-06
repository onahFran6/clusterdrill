# q101-12: Create a Job imperatively

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-12-create-job-imperative`

In namespace `q101-12-create-job-imperative`, create a Job named `hash-once` that runs image
`busybox:1.36` and executes the command `sha256sum /etc/hostname`.

Use a single imperative `kubectl create job` command (with an inline command override), not a
hand-written Job manifest. The Job should run to completion.

## Hint

Search kubernetes.io/docs for **"kubectl create job"** - the `kubectl create job` command
reference shows how to pass a container command after `--`.
