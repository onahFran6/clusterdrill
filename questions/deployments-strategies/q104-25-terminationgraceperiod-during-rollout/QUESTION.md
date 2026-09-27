# q104-25: Shorten pod shutdown wait on a Deployment

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-25-terminationgraceperiod-during-rollout`

A Deployment named `worker-queue` already exists in namespace
`q104-25-terminationgraceperiod-during-rollout` with 3 replicas of image `busybox:1.36`
(command `sleep 3600`). It still uses the default `terminationGracePeriodSeconds`.

Update the Deployment's pod template so `terminationGracePeriodSeconds` is `5`, then confirm
the Deployment reaches 3 ready replicas again.

## Hint

Search kubernetes.io/docs for **"terminationGracePeriodSeconds"** - the Pod Lifecycle page
explains this field controls how long the kubelet waits after SIGTERM before SIGKILL, and it
lives on the pod template so a Deployment edit triggers a new rollout to pick it up. The API
default is 30 seconds.
