# q104-47-rollout-stuck-resourcequota-exceeded: Fix a rollout stuck on a namespace ResourceQuota

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-47-rollout-stuck-resourcequota-exceeded`

`setup.sh` already created a Deployment named `checkout-worker` in namespace
`q104-47-rollout-stuck-resourcequota-exceeded` with 1 replica, originally healthy on image
`busybox:1.35` (command `sleep 3600`) requesting `cpu: 300m` / limiting `cpu: 300m`. A rollout was
then started to image `busybox:1.36` **and**, at the same time, someone bumped the container's CPU
footprint to `requests.cpu: 550m` / `limits.cpu: 550m` for the new revision.

That combination is now stuck: the namespace's `ResourceQuota` (`kubectl get resourcequota -n
q104-47-rollout-stuck-resourcequota-exceeded`) hard-caps `requests.cpu` at `600m` total. The old
pod (still running, `300m`) plus the new revision's surge pod (`550m`) would need `850m` at once,
so the new pod is rejected by admission and never gets created - the rollout can't progress past 0
of 1 replicas updated.

Without changing the image (leave it at `busybox:1.36`), fix the container's CPU footprint so the
rollout fits within the quota: set **both** `requests.cpu` and `limits.cpu` to exactly `200m`.
Confirm the Deployment reaches 1 ready replica on `busybox:1.36` at that CPU footprint.

## Hint

Search kubernetes.io/docs for **"resourcequota requests.cpu"** - the Resource Quotas concept page
explains how a namespace-wide `requests.cpu` cap can reject a new pod outright at admission time
if creating it would push the namespace's total requested CPU over the quota, even while an old
pod is only temporarily still around.
