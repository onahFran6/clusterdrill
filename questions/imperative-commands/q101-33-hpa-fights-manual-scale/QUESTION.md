# q101-33-hpa-fights-manual-scale: Diagnose why a manual scale-down doesn't stick

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-33-hpa-fights-manual-scale`

`setup.sh` already created a Deployment named `email-worker` (image `busybox:1.36`, 3 replicas,
each container requesting `cpu: 25m` / `memory: 32Mi`) together with a HorizontalPodAutoscaler
named `email-worker` in namespace `q101-33-hpa-fights-manual-scale`, keeping `email-worker`'s
replica count between `3` and `6` on `50%` average CPU utilization.

A teammate says they already ran `kubectl scale deployment/email-worker --replicas=1` to cut
costs overnight, and swears it worked - but every time they check back, `email-worker` is back
to 3 replicas. Reproduce the problem yourself (try the same `kubectl scale` command and watch
what happens to the replica count a few seconds later), work out which object is overriding the
manual scale, and fix it **imperatively** so that:

- `email-worker` ends up running with exactly `1` replica, and
- it stays at `1` replica afterward (nothing scales it back up on its own).

Any imperative `kubectl` technique is acceptable (for example `kubectl patch hpa`,
`kubectl edit hpa`, or removing the HorizontalPodAutoscaler outright) as long as the Deployment
settles on exactly 1 replica and stays there.

## Hint

Search kubernetes.io/docs for **"horizontal pod autoscaler minReplicas maxReplicas"** - the
HorizontalPodAutoscaler walkthrough explains how `minReplicas` bounds whatever replica count a
Deployment is scaled to, whether that scale came from the autoscaler itself or from a manual
`kubectl scale`.
