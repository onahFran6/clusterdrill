# q103-34: Give a pod enough time to shut down gracefully before it's killed

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-34-pod-terminationgraceperiod-window`

`setup.sh` wrote an incomplete pod manifest to
`~/practice-work/q103-34-pod-terminationgraceperiod-window/slow-shutdown.yaml` in your terminal's
working directory. It has not been applied yet.

This pod's application needs up to `90` seconds to flush in-flight work and close its connections
cleanly once it receives a termination signal. Kubernetes' default grace period is only `30`
seconds - if the container hasn't exited by then, the kubelet sends `SIGKILL`, cutting the
shutdown short.

Complete `slow-shutdown.yaml` by adding `.spec.terminationGracePeriodSeconds: 90`, then apply it
and confirm the pod reaches `Running`. Do not change the container image (`busybox:1.36`) or
command (`sleep 3600`).

## Hint

Search kubernetes.io/docs for **"terminationGracePeriodSeconds"** - the Pod Lifecycle concept
page's section on pod termination explains the default 30-second grace period and how
`.spec.terminationGracePeriodSeconds` extends it.
