# q107-33: Record a change-cause for a Deployment's rollout history

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-33-rollout-history-change-cause`

`setup.sh` already created a Deployment named `web-app` running `nginx:1.24-alpine`, with no
`kubernetes.io/change-cause` recorded. Update `web-app`'s image to `nginx:1.25-alpine`, and make
sure the resulting rollout is recorded with change-cause exactly
`upgrade nginx to 1.25-alpine`, visible in `kubectl rollout history`.

## Hint

Search kubernetes.io/docs for **"checking rollout history of a deployment"** - the rolling update
task page explains that `kubectl rollout history` reads the Deployment's
`kubernetes.io/change-cause` annotation, which you can set directly with `kubectl annotate` before
triggering the change.
