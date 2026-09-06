# q104-50-deployment-missing-serviceaccount-blocks-rollout: Fix a Deployment referencing a typoed ServiceAccount

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-50-deployment-missing-serviceaccount-blocks-rollout`

`setup.sh` already created a ServiceAccount named `payments-runner` and a Deployment named
`payments-worker` in namespace `q104-50-deployment-missing-serviceaccount-blocks-rollout` with 2
replicas. But `payments-worker`'s pod template sets `spec.serviceAccountName:
payments-runnner` (an extra `n` - it doesn't match the ServiceAccount that actually exists). The
API server's ServiceAccount admission control rejects every pod creation attempt for a
non-existent ServiceAccount, so the ReplicaSet can't create any pods at all and the Deployment has
never once been Ready.

Inspect the Deployment and the namespace's ServiceAccounts (`kubectl get serviceaccount -n
q104-50-deployment-missing-serviceaccount-blocks-rollout`) to spot the mismatch, then fix
`payments-worker`'s `spec.template.spec.serviceAccountName` to the correct, existing
`payments-runner`, and confirm both replicas reach Ready.

## Hint

Search kubernetes.io/docs for **"configure service account pod"** - the Configure Service Accounts
task shows the `spec.serviceAccountName` field, and how a pod referencing a ServiceAccount that
doesn't exist in its namespace fails admission before the pod object is even created.
