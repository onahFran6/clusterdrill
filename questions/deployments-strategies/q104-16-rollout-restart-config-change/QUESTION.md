# q104-16: Force a rolling restart after an external config change

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-16-rollout-restart-config-change`

A ConfigMap named `app-settings` and a Deployment named `worker-pool` (3 replicas, image
`nginx:1.24-alpine`) already exist in namespace `q104-16-rollout-restart-config-change`. The
pods pull `app-settings` via `envFrom`. The ConfigMap was updated, but the running pods still
have the old values in memory.

Without changing the Deployment's pod template (no image change, no manual edit of the spec),
force `worker-pool`'s pods to restart and pick up the current ConfigMap contents. Confirm all 3
replicas come back up healthy.

## Hint

Search kubernetes.io/docs for **"kubectl rollout restart"** - the `kubectl rollout` command
reference documents `restart` as a way to recreate a Deployment's pods without changing its
spec. Kubernetes does not restart pods automatically when a ConfigMap mounted via `envFrom`
changes; a rollout restart is the usual fix.
