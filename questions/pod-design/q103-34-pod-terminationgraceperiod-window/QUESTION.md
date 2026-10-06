# q103-34: Give a pod enough time to shut down gracefully before it's killed

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-34-pod-terminationgraceperiod-window`

Entropy Research Systems runs a batch process that flushes buffered results to disk before
exiting - killed too early, it loses unsaved work. An incomplete pod manifest for it is at
`~/practice-work/q103-34-pod-terminationgraceperiod-window/slow-shutdown.yaml` in your terminal's
working directory. It has not been applied yet.

This pod needs `90` seconds after a termination signal to finish shutdown.

Set `.spec.terminationGracePeriodSeconds` to `90`, apply the manifest, and confirm the pod
reaches `Running`. Do not change the container image (`busybox:1.36`) or command (`sleep 3600`).

## Hint

Search kubernetes.io/docs for **"terminationGracePeriodSeconds"** - the Pod Lifecycle concept
page's section on pod termination explains the default 30-second grace period and how
`.spec.terminationGracePeriodSeconds` extends it. After the grace period, the kubelet sends
`SIGKILL`.
