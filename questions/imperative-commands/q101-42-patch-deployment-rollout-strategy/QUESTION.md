# q101-42-patch-deployment-rollout-strategy: Patch a Deployment's rolling update strategy

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-42-patch-deployment-rollout-strategy`

`setup.sh` already created a Deployment named `checkout-api` (image `nginx:1.25-alpine`, 4 replicas)
in namespace `q101-42-patch-deployment-rollout-strategy`, using the default `RollingUpdate`
strategy values.

Without hand-editing a manifest, use a single imperative `kubectl patch deployment` command
(strategic merge patch) to change its rolling update strategy so that `maxSurge` is `1` and
`maxUnavailable` is `0` - a zero-downtime rollout policy that never drops below the current replica
count while updating.

## Hint

Search kubernetes.io/docs for **"deployment max unavailable max surge"** - the Deployments concept
page's "Rolling Update Deployment" section documents `spec.strategy.rollingUpdate.maxSurge` and
`maxUnavailable`, and `kubectl patch` is the way to change them without hand-editing YAML.
