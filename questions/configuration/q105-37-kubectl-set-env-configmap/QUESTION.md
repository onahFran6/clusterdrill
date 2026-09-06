# q105-37-kubectl-set-env-configmap: Inject a ConfigMap into a running Deployment imperatively

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-37-kubectl-set-env-configmap`

`setup.sh` already created, in namespace `q105-37-kubectl-set-env-configmap`:

- a ConfigMap named `feature-flags` with keys `DARK_MODE=true` and `BETA_UI=false`, and
- a Deployment named `web-frontend` (1 replica, image `nginx:1.25-alpine`) whose container has no
  environment configuration yet.

Without hand-editing the Deployment's YAML, use a single `kubectl set env` command to bulk-import
every key from `feature-flags` into `web-frontend`'s container as environment variables, and let
the resulting rollout complete. Do not change the ConfigMap.

## Hint

Search kubernetes.io/docs for **"kubectl set env"** - the kubectl Reference Docs' `set env`
command page shows the `--from=configmap/<name>` form for bulk-importing a ConfigMap's keys into
a workload's containers without editing a manifest by hand.
