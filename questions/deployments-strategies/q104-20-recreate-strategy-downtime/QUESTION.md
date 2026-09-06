# q104-20-recreate-strategy-downtime: Switch a Deployment to the Recreate strategy

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-20-recreate-strategy-downtime`

`setup.sh` already created a Deployment named `billing-worker` (image `busybox:1.36`, 4 replicas)
in namespace `q104-20-recreate-strategy-downtime`, using the default `RollingUpdate` strategy.

The billing team has determined `billing-worker` must never run old and new pod versions at the
same time (it holds an exclusive lock on a downstream ledger). Change its update strategy to
`Recreate`, so future rollouts terminate all existing pods before creating replacement pods. Do
not change the replica count or the image. Do not leave any `rollingUpdate` fields set - they are
invalid once the strategy type is `Recreate`.

## Hint

Search kubernetes.io/docs for **"Deployment Recreate strategy"** - the Deployment concept page
covers `.spec.strategy.type` and explains why `rollingUpdate` only applies to the `RollingUpdate`
strategy type.
