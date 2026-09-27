# q104-47: Unstick a rollout blocked by ResourceQuota

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-47-rollout-stuck-resourcequota-exceeded`

A Deployment named `checkout-worker` already exists in namespace
`q104-47-rollout-stuck-resourcequota-exceeded` with 1 replica. A rollout to image `busybox:1.36`
is stuck at 0 of 1 replicas updated - the new pod never appears. The namespace has a
ResourceQuota; inspect it with `kubectl get resourcequota -n
q104-47-rollout-stuck-resourcequota-exceeded`.

Without changing the image (leave it at `busybox:1.36`), set both `requests.cpu` and
`limits.cpu` on the container to exactly `200m`. Confirm the Deployment reaches 1 ready replica
on that footprint.

## Hint

Search kubernetes.io/docs for **"resourcequota requests.cpu"** - the Resource Quotas concept page
explains how a namespace-wide `requests.cpu` cap can reject a new pod at admission if creating it
would push the namespace over quota. During a rolling update the old pod can still be consuming
quota while the surge pod tries to start, so a larger CPU request on the new revision can leave
the rollout unable to progress.
