# q105-34-configmap-checksum-rollout-trigger: Force a rollout when a mounted ConfigMap changes, using a checksum annotation

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-34-configmap-checksum-rollout-trigger`

`setup.sh` already created a ConfigMap named `app-config` (key `GREETING`) and a Deployment named
`worker` (2 replicas) whose pod template mounts `app-config` as a volume at `/etc/app`. Each
`worker` container copies `/etc/app/GREETING` to `/var/run/baked-greeting` **once, at container
startup**, then just sleeps - it never re-reads the file again, so a live kubelet volume-sync
update to the mounted file has no effect on a pod that is already running.

The pod template also carries an annotation `checksum/config`, whose entire purpose is to change
- and thereby force a fresh rollout - whenever `app-config`'s contents change. Since the
Deployment was last rolled out, someone updated `app-config`'s `GREETING` key to `hello-v2`, but
never recomputed or repatched the annotation. Because the pod template itself never changed,
nothing forced a rollout, and the two currently-running `worker` pods are still serving
`hello-v1`, baked in at their last startup.

Fix this **without modifying `app-config` itself**:

1. Recompute the sha256 checksum of `app-config`'s current `data`
   (`kubectl get configmap app-config -o jsonpath='{.data}' | sha256sum` is one way to get it).
2. Update the `worker` Deployment's pod template annotation `checksum/config` to that new
   checksum value, so the pod template hash changes and a genuine new rollout is triggered.
3. Let the rollout finish.

When you are done: the `worker` Deployment's pod template annotation `checksum/config` must equal
the current sha256 checksum of `app-config`'s `data`; exactly one new rollout must have happened
(the Deployment should own exactly two ReplicaSets - the original plus the one you triggered, no
more); and every ready `worker` pod's `/var/run/baked-greeting` must contain `hello-v2` from its
fresh startup.

## Hint

Search kubernetes.io/docs for **"Updating a Deployment"** - the Deployments concept page explains
that a rollout is triggered when, and only when, the Deployment's pod template (`.spec.template`)
changes, which is exactly why teams stamp a config checksum into a pod template annotation: it
turns an otherwise-invisible ConfigMap/Secret content change into a pod template change.
