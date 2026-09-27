# q104-20: Replace all pods before starting new ones on update

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-20-recreate-strategy-downtime`

A Deployment named `billing-worker` (image `busybox:1.36`, 4 replicas) already exists in
namespace `q104-20-recreate-strategy-downtime`, using the default `RollingUpdate` strategy.

`billing-worker` must never run old and new pod versions at the same time. Change its update
strategy to `Recreate` so future rollouts terminate all existing pods before creating
replacements. Do not change the replica count or the image. Do not leave any `rollingUpdate`
fields set - they are invalid once the strategy type is `Recreate`.

## Hint

Search kubernetes.io/docs for **"Deployment Recreate strategy"** - the Deployment concept page
covers `.spec.strategy.type` and explains why `rollingUpdate` only applies to the
`RollingUpdate` strategy type.
