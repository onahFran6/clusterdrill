# q101-17: Create a ServiceAccount and attach it to a pod imperatively

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-17-create-serviceaccount-imperative`

In namespace `q101-17-create-serviceaccount-imperative`:

1. Create a ServiceAccount named `deploy-bot` using an imperative `kubectl create` command.
2. Create a pod named `bot-runner` running image `busybox:1.36` (command `sleep 3600`) that runs
   as that ServiceAccount.

Both steps should be done with imperative commands - no hand-written manifests.

## Hint

Search kubernetes.io/docs for **"kubectl create serviceaccount"** and **"kubectl run
--serviceaccount"** - the ServiceAccount concept page and the `kubectl run` reference both cover
these two steps.
