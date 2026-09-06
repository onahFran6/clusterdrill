# q104-16: Force a rolling restart after an external config change

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-16-rollout-restart-config-change`

`setup.sh` already created a ConfigMap named `app-settings` and a Deployment named `worker-pool`
(3 replicas, image `nginx:1.24-alpine`) in namespace `q104-16-rollout-restart-config-change`. The
Deployment's pods mount `app-settings` as environment variables via `envFrom`, but Kubernetes does
not automatically restart pods when a ConfigMap's data changes underneath them - the pods now
have stale env vars in memory even though `app-settings` was already updated moments ago.

Without changing the Deployment's pod template (no image change, no manual edit of the spec),
force `worker-pool`'s pods to restart and pick up the current ConfigMap contents, and confirm all
3 replicas come back up healthy.

## Hint

Search kubernetes.io/docs for **"kubectl rollout restart"** - the `kubectl rollout` command
reference documents `restart` as a way to recreate a Deployment's pods without changing its
spec, useful exactly when an external dependency (like a ConfigMap) changed but the template
didn't.
