# q104-25-terminationgraceperiod-during-rollout: Shorten a Deployment's termination grace period

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-25-terminationgraceperiod-during-rollout`

`setup.sh` already created a Deployment named `worker-queue` (3 replicas, image `busybox:1.36`,
command `sleep 3600`) in namespace `q104-25-terminationgraceperiod-during-rollout`. It uses the
default `terminationGracePeriodSeconds` (30), which means every future rollout waits up to 30s per
pod before force-killing it.

Update the Deployment's pod template so `terminationGracePeriodSeconds` is `5`, then confirm the
Deployment reaches 3 ready replicas again.

## Hint

Search kubernetes.io/docs for **"terminationGracePeriodSeconds"** - the Pod Lifecycle page explains
this field controls how long the kubelet waits after sending SIGTERM before sending SIGKILL, and it
lives on the pod template so a Deployment edit triggers a new rollout to pick it up.
