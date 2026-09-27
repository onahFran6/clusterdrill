# q101-33: Make a manual scale-down stick

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-33-hpa-fights-manual-scale`

A Deployment named `email-worker` (image `busybox:1.36`, 3 replicas, each container requesting
`cpu: 25m` / `memory: 32Mi`) exists in namespace `q101-33-hpa-fights-manual-scale`, along with a
HorizontalPodAutoscaler also named `email-worker` that keeps the replica count between `3` and
`6` on `50%` average CPU utilization.

A teammate ran `kubectl scale deployment/email-worker --replicas=1`, but every time they check
back, `email-worker` is back at 3 replicas. Reproduce the problem, work out what is overriding the
manual scale, and fix it imperatively so that:

- `email-worker` ends up running with exactly `1` replica, and
- it stays at `1` replica afterward.

Any imperative `kubectl` technique is acceptable as long as the Deployment settles on exactly 1
replica and stays there.

## Hint

Search kubernetes.io/docs for **"horizontal pod autoscaler minReplicas maxReplicas"** - the
HorizontalPodAutoscaler walkthrough explains how `minReplicas` bounds whatever replica count a
Deployment is scaled to, whether that scale came from the autoscaler itself or from a manual
`kubectl scale`.
