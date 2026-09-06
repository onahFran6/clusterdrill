# q104-14: Diagnose a rollout stuck behind a failing readiness probe

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-14-readiness-gate-stuck-rollout`

`setup.sh` already created a Deployment named `inventory` in namespace
`q104-14-readiness-gate-stuck-rollout` with 3 replicas on image `nginx:1.24-alpine`, and started a
rollout to image `nginx:1.25-alpine`. That rollout is now stuck: the new ReplicaSet's pods have a
`readinessProbe` pointed at a path (`/does-not-exist`) that always returns a non-2xx status, so
they never become Ready and the default `maxUnavailable` prevents the old pods from being
replaced any further.

Without changing the image, record the Deployment's current rollout condition into a ConfigMap
named `diagnosis` (in the same namespace) with a single key `progressing-status` whose value is
the `status` field of the Deployment's `Progressing` condition (as reported by
`kubectl get deployment inventory -o jsonpath` against `.status.conditions`) - this should read
`"False"` once the rollout has stalled past its `progressDeadlineSeconds`. Do not fix the probe;
this question is about reading the Deployment's own stuck-rollout signal.

## Hint

Search kubernetes.io/docs for **"deployment progress deadline seconds"** - the Deployment concept
page's "Failed Deployment" section explains the `Progressing` condition and how
`progressDeadlineSeconds` determines when a rollout is reported as stalled.
