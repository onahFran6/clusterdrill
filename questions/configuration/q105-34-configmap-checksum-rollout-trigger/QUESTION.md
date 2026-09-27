# q105-34: Roll out workers after ConfigMap content changes

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-34-configmap-checksum-rollout-trigger`

A ConfigMap named `app-config` (key `GREETING`) and a Deployment named `worker` (2 replicas)
exist in namespace `q105-34-configmap-checksum-rollout-trigger`. Each `worker` container mounts
`app-config` at `/etc/app`, copies `/etc/app/GREETING` to `/var/run/baked-greeting` once at
startup, then sleeps - it never re-reads the file. The pod template carries an annotation
`checksum/config` that teams update when `app-config` changes so a fresh rollout starts.

Someone already updated `app-config`'s `GREETING` to `hello-v2`, but the running pods still serve
`hello-v1` from their last startup.

Fix this **without modifying `app-config` itself**:

1. Recompute the sha256 checksum of `app-config`'s current `data`
   (`kubectl get configmap app-config -o jsonpath='{.data}' | sha256sum` is one way).
2. Update the `worker` Deployment's pod template annotation `checksum/config` to that new value
   so a rollout is triggered.
3. Let the rollout finish.

When done: `checksum/config` must equal the current sha256 of `app-config`'s `data`; the
Deployment should own exactly two ReplicaSets (the original plus the one you triggered); and
every ready `worker` pod's `/var/run/baked-greeting` must contain `hello-v2`.

## Hint

Search kubernetes.io/docs for **"Updating a Deployment"** - the Deployments concept page explains
that a rollout is triggered when, and only when, the Deployment's pod template (`.spec.template`)
changes, which is exactly why teams stamp a config checksum into a pod template annotation: it
turns an otherwise-invisible ConfigMap/Secret content change into a pod template change.
