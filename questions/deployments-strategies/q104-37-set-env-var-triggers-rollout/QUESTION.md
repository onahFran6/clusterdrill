# q104-37: Add an environment variable that rolls the Deployment

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-37-set-env-var-triggers-rollout`

A Deployment named `worker` (container name `worker`, image `busybox:1.36`, command
`sleep 3600`, 2 replicas) already exists in namespace
`q104-37-set-env-var-triggers-rollout`, with no environment variables set, and is fully rolled
out with both replicas Ready.

Using `kubectl set env`, add the environment variable `LOG_LEVEL=debug` to the `worker`
container. Wait until both replicas are Ready again on the updated template.

## Hint

Search kubernetes.io/docs for **"kubectl set env"** - the `kubectl set env` command reference
shows how setting an environment variable on a Deployment updates its pod template directly.
Unlike changing an external ConfigMap or Secret, that template edit starts a new rollout on its
own - no separate restart command is needed.
