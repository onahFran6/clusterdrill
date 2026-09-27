# q104-14: Diagnose a rollout stuck behind a failing readiness probe

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-14-readiness-gate-stuck-rollout`

A Deployment named `inventory` already exists in namespace
`q104-14-readiness-gate-stuck-rollout` with 3 replicas. A rollout to image `nginx:1.25-alpine` is
in progress but stuck: the new ReplicaSet's pods never become Ready, so the update cannot
finish.

Without changing the image or fixing the probe, record the Deployment's current rollout signal
into a ConfigMap named `diagnosis` (same namespace) with a single key `progressing-status` whose
value is the `status` field of the Deployment's `Progressing` condition (from
`kubectl get deployment inventory -o jsonpath` against `.status.conditions`). Once the rollout
has stalled past its progress deadline, that value should be `False`.

## Hint

Search kubernetes.io/docs for **"deployment progress deadline seconds"** - the Deployment concept
page's "Failed Deployment" section explains the `Progressing` condition and how
`progressDeadlineSeconds` marks a stalled rollout. Inspect the new pods' readinessProbe if you
want the reason they never become Ready - leave it alone for this question.
