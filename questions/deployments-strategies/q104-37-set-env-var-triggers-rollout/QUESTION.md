# q104-37-set-env-var-triggers-rollout: Add an environment variable and let it trigger a rollout

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-37-set-env-var-triggers-rollout`

`setup.sh` already created a Deployment named `worker` (container name `worker`, image
`busybox:1.36`, command `sleep 3600`, 2 replicas) in namespace
`q104-37-set-env-var-triggers-rollout`, with no environment variables set, and it is already fully
rolled out with both replicas Ready.

Using `kubectl set env`, add the environment variable `LOG_LEVEL=debug` to the `worker` container.
Unlike an external ConfigMap/Secret change, this directly edits the pod template, so it
automatically starts a new rollout on its own - no separate restart command needed. Wait until
both replicas are Ready again on the updated template.

## Hint

Search kubernetes.io/docs for **"kubectl set env"** - the `kubectl set env` command reference
shows how setting an environment variable on a Deployment updates its pod template directly,
which the Deployment controller then rolls out like any other template change.
